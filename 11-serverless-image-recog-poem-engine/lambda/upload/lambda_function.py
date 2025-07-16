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

    try:
        body = json.loads(event.get("body", "{}"))
        fname = body.get("fileName")
        if not fname:
            logger.warning("No fileName in request")
            return respond(400, {"message": "fileName required"})

        key = f"uploads/{fname}"
        post = s3.generate_presigned_post(
            Bucket=BUCKET,
            Key=key,
            Fields={"Content-Type": "image/jpeg"},
            Conditions=[{"Content-Type": "image/jpeg"}],
            ExpiresIn=60,
        )
        logger.info("Presigned POST created for key %s", key)

        return respond(
            200, {"uploadUrl": post["url"], "fields": post["fields"], "key": key}
        )

    except ClientError as e:
        logger.error("AWS ClientError: %s", e, exc_info=True)
        return respond(500, {"message": "Error creating upload URL"})
    except json.JSONDecodeError:
        logger.error("Invalid JSON body", exc_info=True)
        return respond(400, {"message": "Invalid JSON"})
    except Exception as e:
        logger.exception("Unexpected error")
        return respond(500, {"message": "Internal server error"})


def respond(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
