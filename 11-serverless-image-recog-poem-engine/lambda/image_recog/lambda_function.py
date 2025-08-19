import os
import json
import logging
import boto3
from datetime import datetime, timedelta, timezone
from botocore.exceptions import ClientError

# Logging setup
logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())

rek = boto3.client("rekognition")
S3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
BUCKET = os.environ.get("BUCKET_NAME", "")
TABLE_NAME = os.environ.get("TABLE_NAME", "poem-results")
BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "amazon.titan-text-lite-v1")
AWS_REGION = os.environ.get("AWS_REGION", "ap-south-1")
table = dynamodb.Table(TABLE_NAME)

# Bedrock client using region from env
bedrock = boto3.client("bedrock-runtime", region_name=AWS_REGION)
# IST timezone (+5:30)
ist = timezone(timedelta(hours=5, minutes=30))
now_ist = datetime.now(ist)

# Clean timestamp for filename: YYYYMMDD_hh-mm-ss_AM/PM
filename_timestamp = now_ist.strftime("%Y%m%d_%I-%M-%S_%p")
filename = f"poems/poem_{filename_timestamp}.txt"


def lambda_handler(event, context):
    logger.info("S3 event received: %s", json.dumps(event))

    try:
        record = event["Records"][0]["s3"]
        bucket, key = record["bucket"]["name"], record["object"]["key"]
        logger.info("Processing image s3://%s/%s", bucket, key)
        
        # Extract poemId from S3 object metadata
        try:
            obj_response = S3.head_object(Bucket=bucket, Key=key)
            poem_id = obj_response.get('Metadata', {}).get('poemid')
            if not poem_id:
                # Fallback: extract from filename
                poem_id = key.split('/')[-1].split('_')[0]
        except:
            # Fallback: extract from filename  
            poem_id = key.split('/')[-1].split('_')[0]
        
        logger.info("Processing image with key: %s, using poemId: %s", key, poem_id)

        response = rek.detect_labels(
            Image={"S3Object": {"Bucket": bucket, "Name": key}},
            MaxLabels=5,
            MinConfidence=70,
        )
        labels = [lbl["Name"] for lbl in response.get("Labels", [])]
        logger.info("Labels: %s", labels)

        poem_text = generate_bedrock_poem(labels)
        logger.info("Poem generated successfully")

        # Store result in DynamoDB
        item_data = {
            'poemId': poem_id,
            'labels': labels,
            'poem': poem_text,
            'status': 'completed',
            'timestamp': int(datetime.now().timestamp()),
            'ttl': int(datetime.now().timestamp()) + 3600  # 1 hour TTL
        }
        
        logger.info("Storing item in DynamoDB: %s", json.dumps(item_data, default=str))
        
        table.put_item(Item=item_data)
        logger.info("Poem result stored in DynamoDB with ID: %s", poem_id)

        S3.delete_object(Bucket=bucket, Key=key)
        logger.info("Deleted uploaded image after processing")

        return {
            "statusCode": 200,
            "body": json.dumps({"poemId": poem_id, "labels": labels, "poem": poem_text}),
        }

    except ClientError as err:
        logger.error("ClientError: %s", err, exc_info=True)
        # Try to generate a fallback poem with the labels we might have
        try:
            fallback_poem = generate_fallback_poem(['nature', 'beauty'])
            return {
                "statusCode": 200,
                "body": json.dumps({"labels": ['nature', 'beauty'], "poem": fallback_poem}),
            }
        except:
            return safe_poem("There was an error accessing AWS services.")

    except KeyError as k:
        logger.error("KeyError - missing key: %s", k, exc_info=True)
        return safe_poem("Event structure is invalid.")

    except Exception:
        logger.exception("Unhandled exception occurred")
        return safe_poem("Something went wrong, try again later.")


def generate_bedrock_poem(labels):
    try:
        label_list = ", ".join(labels)
        prompt = (
            f"Given these image labels: {label_list}, "
            f"write a poetic line or quote in 10 words or fewer. "
            f"Do not include any explanation or introduction. "
            f"Output only the poem or quote, nothing else."
        )

        body = {
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 50,
                "temperature": 0.7,
                "topP": 0.9,
            },
        }

        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )

        response_body = json.loads(response["body"].read())
        return (
            response_body.get("results", [{}])[0].get("outputText", "").strip().strip('"')
        )
    except ClientError as e:
        logger.warning("Bedrock not accessible, using fallback poem: %s", e)
        return generate_fallback_poem(labels)
    except Exception as e:
        logger.warning("Error generating Bedrock poem, using fallback: %s", e)
        return generate_fallback_poem(labels)


def generate_fallback_poem(labels):
    """Generate a simple poem based on detected labels when Bedrock is not available"""
    poems = {
        'bird': "Feathers dance on morning breeze,\nNature's song among the trees.",
        'animal': "Wild hearts roam where freedom calls,\nNature's spirit never falls.",
        'flower': "Petals bloom in morning light,\nColors painting pure delight.",
        'nature': "Earth's canvas painted green and gold,\nStories that will never grow old.",
        'water': "Ripples dance on crystal streams,\nReflecting all our hopes and dreams.",
        'sky': "Endless blue above our heads,\nWhere clouds like cotton softly tread.",
        'sunset': "Golden rays kiss earth goodnight,\nPainting skies with fading light.",
        'tree': "Ancient roots and branches high,\nReaching up to touch the sky.",
        'mountain': "Peaks that pierce the morning mist,\nBy golden sunlight gently kissed.",
        'ocean': "Waves that whisper ancient tales,\nOf distant shores and sailing trails."
    }
    
    # Find matching poem based on labels
    for label in labels:
        label_lower = label.lower()
        if label_lower in poems:
            return poems[label_lower]
        # Check for partial matches
        for key in poems:
            if key in label_lower or label_lower in key:
                return poems[key]
    
    # Default poem if no matches
    return "Beauty captured in this frame,\nNature's art without a name."


def write_poem_to_s3(poem, key):
    poem_with_timestamp = f"Generated on: {filename_timestamp}\n\n{poem}"

    S3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=poem_with_timestamp.encode("utf-8"),
        ContentType="text/plain",
    )


def safe_poem(message):
    fallback_poem = f"{message}\n\n_The clouds may hide the view today,_\n_But skies will clear another way._"
    return {
        "statusCode": 500,
        "body": json.dumps({"error": message, "poem": fallback_poem}),
    }
