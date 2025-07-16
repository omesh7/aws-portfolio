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
BUCKET = os.environ.get("BUCKET_NAME", "")
BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "amazon.titan-text-lite-v1")
AWS_REGION = os.environ.get("AWS_REGION", "ap-south-1")

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

        response = rek.detect_labels(
            Image={"S3Object": {"Bucket": bucket, "Name": key}},
            MaxLabels=5,
            MinConfidence=70,
        )
        labels = [lbl["Name"] for lbl in response.get("Labels", [])]
        logger.info("Labels: %s", labels)

        poem_text = generate_bedrock_poem(labels)
        logger.info("Poem generated: %s", poem_text)

        poem_key = filename
        write_poem_to_s3(poem_text, poem_key)
        logger.info("Poem saved to s3://%s/%s", BUCKET, poem_key)

        S3.delete_object(Bucket=bucket, Key=key)
        logger.info("Deleted uploaded image after processing")

        return {
            "statusCode": 200,
            "body": json.dumps({"labels": labels, "poem": poem_text}),
        }

    except ClientError as err:
        logger.error("ClientError: %s", err, exc_info=True)
        return safe_poem("There was an error accessing AWS services.")

    except KeyError as k:
        logger.error("KeyError - missing key: %s", k, exc_info=True)
        return safe_poem("Event structure is invalid.")

    except Exception:
        logger.exception("Unhandled exception occurred")
        return safe_poem("Something went wrong, try again later.")


def generate_bedrock_poem(labels):
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
