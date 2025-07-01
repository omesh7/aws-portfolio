import json
import os
import uuid
import logging
import traceback
from datetime import datetime
import urllib.parse
import boto3
from dateutil import parser as date_parser

# Logging setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
s3 = boto3.client('s3')
textract = boto3.client('textract')
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

# Environment Variables
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
S3_BUCKET_NAME = os.environ.get('NOTIFICATION_LOG_BUCKET')  # Same bucket used for notifications

assert DYNAMODB_TABLE, "Missing env var: DYNAMODB_TABLE"
assert SNS_TOPIC_ARN, "Missing env var: SNS_TOPIC_ARN"
assert S3_BUCKET_NAME, "Missing env var: NOTIFICATION_LOG_BUCKET"

def lambda_handler(event, context):
    logger.info("Lambda function started.")
    logger.info(f"Environment Variables: DYNAMODB_TABLE={DYNAMODB_TABLE}, SNS_TOPIC_ARN={SNS_TOPIC_ARN}, S3_BUCKET_NAME={S3_BUCKET_NAME}")
    logger.debug(f"Received event: {json.dumps(event)}")

    try:
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])

        logger.info(f"Triggered by file: s3://{bucket}/{key}")

        if not key.startswith("uploads/"):
            logger.warning(f"Skipped file not in uploads/: {key}")
            return {'statusCode': 204, 'body': 'File not in uploads/ folder.'}

        s3.head_object(Bucket=bucket, Key=key)
        logger.info("S3 object exists and is accessible.")

        receipt_data = process_receipt_with_textract(bucket, key)
        logger.debug(f"Receipt data extracted: {json.dumps(receipt_data)}")

        store_receipt_in_dynamodb(receipt_data)
        send_sns_notification(receipt_data)
        log_notification_to_s3(receipt_data)

        return {'statusCode': 200, 'body': 'Receipt processed successfully.'}

    except Exception as e:
        error_info = {
            "errorMessage": str(e),
            "traceback": traceback.format_exc(),
            "event": event,
            "context": {
                "aws_request_id": context.aws_request_id if context else None,
                "function_name": context.function_name if context else None
            }
        }
        logger.error("Unhandled error occurred", extra={"error_details": error_info})
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e), 'trace': traceback.format_exc()})
        }

def process_receipt_with_textract(bucket, key):
    try:
        logger.info(f"Calling Textract for: s3://{bucket}/{key}")
        response = textract.analyze_expense(
            Document={'S3Object': {'Bucket': bucket, 'Name': key}}
        )
        logger.debug(f"Textract response: {json.dumps(response)}")
    except Exception as e:
        logger.error(f"Textract failed: {str(e)}", exc_info=True)
        raise

    receipt_id = str(uuid.uuid4())
    receipt_data = {
        'receipt_id': receipt_id,
        'date': datetime.utcnow().strftime('%Y-%m-%d'),
        'vendor': 'Unknown',
        'total': '0.00',
        'items': [],
        's3_path': f"s3://{bucket}/{key}",
        'processed_timestamp': datetime.utcnow().isoformat()
    }

    documents = response.get('ExpenseDocuments', [])
    if not documents:
        logger.warning("No documents found in Textract response.")
        return receipt_data

    summary = documents[0].get('SummaryFields', [])
    for field in summary:
        f_type = field.get('Type', {}).get('Text', '')
        val = field.get('ValueDetection', {}).get('Text', '')

        if f_type == 'TOTAL':
            receipt_data['total'] = val
        elif f_type == 'VENDOR_NAME':
            receipt_data['vendor'] = val
        elif f_type == 'INVOICE_RECEIPT_DATE':
            try:
                parsed = date_parser.parse(val)
                receipt_data['date'] = parsed.strftime('%Y-%m-%d')
            except Exception as e:
                logger.warning(f"Failed to parse receipt date: {val}, error: {e}")

    items = []
    for group in documents[0].get('LineItemGroups', []):
        for line in group.get('LineItems', []):
            item = {}
            for field in line.get('LineItemExpenseFields', []):
                t = field.get('Type', {}).get('Text', '')
                v = field.get('ValueDetection', {}).get('Text', '')
                if t == 'ITEM':
                    item['name'] = v
                elif t == 'PRICE':
                    item['price'] = v
                elif t == 'QUANTITY':
                    item['quantity'] = v
            if item:
                items.append(item)

    receipt_data['items'] = items
    return receipt_data

def store_receipt_in_dynamodb(receipt_data):
    try:
        table = dynamodb.Table(DYNAMODB_TABLE)
        table.put_item(Item=receipt_data)
        logger.info(f"Stored receipt in DynamoDB: {receipt_data['receipt_id']}")
    except Exception as e:
        logger.error(f"Error storing receipt in DynamoDB: {str(e)}", exc_info=True)
        raise

def send_sns_notification(receipt_data):
    subject = f"Receipt: {receipt_data['vendor']} - ${receipt_data['total']}"
    message = (
        f"Receipt ID: {receipt_data['receipt_id']}\n"
        f"Vendor: {receipt_data['vendor']}\n"
        f"Date: {receipt_data['date']}\n"
        f"Total: ${receipt_data['total']}\n\n"
        "Items:\n" +
        "\n".join([
            f"- {item.get('name', 'Unknown')} (${item.get('price', '0.00')} x {item.get('quantity', '1')})"
            for item in receipt_data['items']
        ])
    )
    try:
        response = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        logger.info("SNS notification sent.")
        logger.debug(f"SNS publish response: {json.dumps(response)}")
    except Exception as e:
        logger.error(f"Error sending SNS notification: {str(e)}", exc_info=True)
        raise

def log_notification_to_s3(receipt_data):
    key = f"notifications/{receipt_data['receipt_id']}.json"
    try:
        logger.info(f"Logging notification to s3://{S3_BUCKET_NAME}/{key}")
        s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=key,
            Body=json.dumps(receipt_data, indent=2),
            ContentType='application/json'
        )
        logger.info(f"Saved log to s3://{S3_BUCKET_NAME}/{key}")
    except Exception as e:
        logger.warning(f"Failed to write notification to S3: {str(e)}", exc_info=True)
