import os
import json
import logging
import boto3
from decimal import Decimal
from botocore.exceptions import ClientError

# Logging setup
logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("TABLE_NAME", "poem-results")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    logger.info("Get poem request: %s", json.dumps(event))
    
    try:

        # Extract poem ID from query parameters
        query_params = event.get("queryStringParameters")
        if query_params is None:
            logger.error("No query parameters found in event: %s", json.dumps(event))
            return respond(400, {"error": "No query parameters"})
        
        poem_id = query_params.get("poemId")
        
        logger.info("Looking for poem with ID: %s", poem_id)
        
        if not poem_id:
            return respond(400, {"error": "poemId parameter required"})
        
        # Get result from DynamoDB
        logger.info("Querying DynamoDB table: %s for poemId: %s", TABLE_NAME, poem_id)
        response = table.get_item(Key={"poemId": poem_id})
        
        logger.info("DynamoDB response: %s", json.dumps(response, default=str))
        
        if "Item" not in response:
            logger.info("No item found for poemId: %s", poem_id)
            return respond(404, {"status": "processing", "message": "Poem not ready yet"})
        
        item = response["Item"]
        logger.info("Found poem item: %s", json.dumps(item, default=str))
        
        # Convert DynamoDB format to regular format
        result = {
            "status": item.get("status"),
            "labels": item.get("labels"),
            "poem": item.get("poem"),
            "timestamp": int(item.get("timestamp", 0))  # Convert Decimal to int
        }
        
        return respond(200, result)
        
    except ClientError as e:
        logger.error("DynamoDB error: %s", e, exc_info=True)
        return respond(500, {"error": "Database error"})
    except Exception as e:
        logger.exception("Unexpected error")
        return respond(500, {"error": "Internal server error"})

def respond(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body),
    }