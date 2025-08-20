import os
import json
import logging
import boto3
from botocore.exceptions import ClientError

# Logging setup
logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("TABLE_NAME", "poem-results")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    logger.info("GET poem event: %s", json.dumps(event))

    try:
        # Extract poemId from query parameters
        query_params = event.get("queryStringParameters") or {}
        poem_id = query_params.get("poemId")

        if not poem_id:
            return respond(400, {"error": "poemId parameter required"})

        logger.info("Looking up poem with ID: %s", poem_id)

        # Get item from DynamoDB
        response = table.get_item(Key={"poemId": poem_id})

        if "Item" not in response:
            logger.info("Poem not found for ID: %s", poem_id)
            return respond(404, {"error": "Poem not found", "status": "processing"})

        item = response["Item"]
        logger.info("Found poem: %s", json.dumps(item, default=str))

        return respond(
            200,
            {
                "status": item.get("status", "completed"),
                "labels": item.get("labels", []),
                "poem": item.get("poem", ""),
                "poemId": poem_id,
                "timestamp": int(item.get("timestamp", 0)),
            },
        )

    except ClientError as e:
        logger.error("DynamoDB error: %s", e, exc_info=True)
        return respond(500, {"error": "Database error"})
    except Exception as e:
        logger.exception("Unexpected error")
        return respond(500, {"error": "Internal server error"})


def respond(status, body):

    return {"statusCode": status, "body": json.dumps(body)}

