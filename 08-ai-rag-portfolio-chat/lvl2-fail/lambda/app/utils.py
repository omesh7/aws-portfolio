import os, json
from typing import Dict, Any
import json
import boto3
from aws_lambda_powertools import Logger

# ENV's
BUCKET = os.environ["BUCKET"]
EMBEDDING_MODEL_ID = os.environ["EMBEDDING_MODEL_ID"]
MODEL_ID = os.environ["MODEL_ID"]
MEMORY_TABLE = os.environ["MEMORY_TABLE"]
DOCUMENT_TABLE = os.environ["DOCUMENT_TABLE"]
QUEUE = os.environ["QUEUE"]


SOUTH_REGION = "ap-south-1"
EAST_REGION = "us-east-1"

ddb = boto3.resource("dynamodb")
document_table = ddb.Table(DOCUMENT_TABLE)
memory_table = ddb.Table(MEMORY_TABLE)
sqs = boto3.client("sqs")
s3 = boto3.client("s3")
logger = Logger()


def response(body: Any, status_code: int = 200) -> Dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "*",
        },
        "body": json.dumps(body, default=str),
    }


def get_path_param(event: Dict[str, Any], key: str) -> str:
    return event.get("pathParameters", {}).get(key, "")


def error_response(message: str, status_code: int = 400) -> Dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": message}),
    }


from typing import Dict, Any


def get_user_id(event: Dict[str, Any]) -> str:
    try:
        return event["requestContext"]["authorizer"]["claims"]["sub"]
    except KeyError:
        # fallback to source IP if not using Cognito
        return (
            event.get("requestContext", {}).get("http", {}).get("sourceIp", "anonymous")
        )
