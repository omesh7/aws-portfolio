import json
import boto3
import base64
import uuid

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("anomaly-stream-records")


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