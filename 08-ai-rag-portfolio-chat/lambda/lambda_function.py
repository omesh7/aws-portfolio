import boto3
import os
import json
import logging
import uuid
from urllib.parse import unquote_plus
from botocore.exceptions import ClientError

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set up S3 clients per region
s3_client_docs = boto3.client("s3", region_name="ap-south-1")
s3_client_vector = boto3.client("s3", region_name="us-east-1")

# Constants
SOURCE_BUCKET = os.environ.get("SOURCE_BUCKET")  # ap-south-1
VECTOR_BUCKET = os.environ.get("VECTOR_BUCKET")  # us-east-1
VECTOR_INDEX_PREFIX = "vector-indexes/"


def dummy_embed_text(text):
    """Fake embedding function — replace with your real embedding model"""
    return [ord(c) for c in text[:50]]  # Simple list of char codes


def save_vector_index(chunks, file_name):
    try:
        logger.info(f"Saving vector index for file: {file_name}")
        index_data = {
            "file": file_name,
            "vectors": [dummy_embed_text(chunk) for chunk in chunks],
        }

        key = f"{VECTOR_INDEX_PREFIX}{file_name}.json"
        local_path = f"/tmp/{file_name}_vector.json"

        with open(local_path, "w") as f:
            json.dump(index_data, f)

        logger.info(f"Uploading to vector bucket: {VECTOR_BUCKET}, Key: {key}")
        if not VECTOR_BUCKET or not key:
            raise ValueError("VECTOR_BUCKET or key is None!")

        s3_client_vector.upload_file(local_path, VECTOR_BUCKET, key)
        logger.info("Upload completed successfully.")

    except Exception as e:
        logger.error(f"Failed to save vector index: {str(e)}", exc_info=True)
        raise


def process_s3_file(bucket_name, object_key):
    try:
        logger.info(f"Downloading file: {object_key} from {bucket_name}")
        response = s3_client_docs.get_object(Bucket=bucket_name, Key=object_key)
        content = response["Body"].read().decode("utf-8")

        chunks = content.split("\n\n")  # Dummy chunking
        save_vector_index(chunks, object_key.replace("/", "_"))

    except Exception as e:
        logger.error(f"Error processing file: {e}", exc_info=True)
        raise


def lambda_handler(event, context):
    logger.info("Lambda triggered")
    try:
        # Handle S3 trigger event
        if "Records" in event and "s3" in event["Records"][0]:
            for record in event["Records"]:
                s3_info = record["s3"]
                bucket = s3_info["bucket"]["name"]
                key = unquote_plus(s3_info["object"]["key"])
                logger.info(f"S3 Triggered file: {key}")
                process_s3_file(bucket, key)

        # Handle manual/API trigger
        elif "file_key" in event:
            file_key = event["file_key"]
            logger.info(f"Manual/API Triggered with file: {file_key}")
            process_s3_file(SOURCE_BUCKET, file_key)

        else:
            logger.warning("Event format not recognized")
            return {"statusCode": 400, "body": json.dumps("Invalid event")}

        return {"statusCode": 200, "body": json.dumps("Processing complete")}

    except Exception as e:
        logger.critical("Fatal error in lambda_handler", exc_info=True)
        return {"statusCode": 500, "body": json.dumps(f"Error: {str(e)}")}

##---------------------------------------------------------------------------------------


from typing import Dict, Any
from utils.router import route_request
from utils.response import error_response

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        return route_request(event)
    except Exception as e:
        return error_response(str(e), 500)
