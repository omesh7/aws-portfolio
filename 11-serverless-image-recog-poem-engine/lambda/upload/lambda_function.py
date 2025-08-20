import os
import json
import logging
import boto3
from botocore.exceptions import ClientError

# Logging setup
logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())

s3 = boto3.client("s3", config=boto3.session.Config(signature_version="s3v4"))
BUCKET = os.environ["BUCKET_NAME"]  # Must be set in Lambda env


def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))
    logger.info("Environment variables: BUCKET_NAME=%s", os.environ.get("BUCKET_NAME", "NOT_SET"))
    
    # Handle CORS preflight
    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return respond(200, {"message": "OK"})

    try:
        body = json.loads(event.get("body", "{}"))
        fname = body.get("fileName")
        if not fname:
            logger.warning("No fileName in request")
            return respond(400, {"message": "fileName required"})

        # Generate unique random poem ID
        import uuid
        poem_id = str(uuid.uuid4())[:8]  # Short unique ID
        
        key = f"uploads/{poem_id}_{fname}"
        post = s3.generate_presigned_post(
            Bucket=BUCKET,
            Key=key,
            Fields={
                "Content-Type": "image/jpeg",
                "x-amz-meta-poemid": poem_id
            },
            Conditions=[
                {"Content-Type": "image/jpeg"},
                ["content-length-range", 0, 5242880],  # 5MB max
                ["starts-with", "$x-amz-meta-poemid", ""]
            ],
            ExpiresIn=300,  # 5 minutes
        )
        
        # Use regional S3 endpoint to avoid redirects
        if "s3.amazonaws.com" in post["url"]:
            post["url"] = post["url"].replace(
                "s3.amazonaws.com", 
                "s3.ap-south-1.amazonaws.com"
            )
        logger.info("Presigned POST created for key %s", key)

        logger.info("Generated poemId: %s for file: %s", poem_id, fname)
        
        return respond(
            200, {
                "uploadUrl": post["url"], 
                "fields": post["fields"], 
                "key": key,
                "poemId": poem_id
            }
        )

    except ClientError as e:
        logger.error("AWS ClientError: %s", e, exc_info=True)
        return respond(500, {"message": f"AWS Error: {str(e)}"})
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON body: %s", e, exc_info=True)
        return respond(400, {"message": f"Invalid JSON: {str(e)}"})
    except Exception as e:
        logger.exception("Unexpected error: %s", str(e))
        return respond(500, {"message": f"Internal server error: {str(e)}"})


def respond(status, body):
    return {
        "statusCode": status,
    
        "body": json.dumps(body),
    }
