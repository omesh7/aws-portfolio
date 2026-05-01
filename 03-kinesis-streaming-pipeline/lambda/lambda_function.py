import json
import boto3
import base64
import uuid
import os

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get('DYNAMODB_TABLE', 'anomaly-stream-records')
table = dynamodb.Table(table_name)


def lambda_handler(event, context):
    for record in event["Records"]:
        payload = json.loads(
            base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
        )
        table.put_item(
            Item={
                "id": str(uuid.uuid4()),
                "source": payload.get("source"),
                "amount": payload.get("amount"),
                "timestamp": payload.get("timestamp"),
            }
        )
    return {"status": "ok"}
# This Lambda function processes records from a Kinesis stream, decodes the data,