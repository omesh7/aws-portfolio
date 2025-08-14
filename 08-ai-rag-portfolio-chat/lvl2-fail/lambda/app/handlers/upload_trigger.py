import urllib
from zoneinfo import ZoneInfo
import shortuuid
import PyPDF2
from datetime import datetime, timezone
import json

from ..utils import (
    logger,
    document_table,
    s3,
    memory_table,
    BUCKET,
    sqs,
    QUEUE,
)


local_timezone = ZoneInfo("Asia/Kolkata")  # Replace with your actual timezone

def handler(event):
    logger.info("Triggered by S3 event", extra={"event": event})
    try:
        key = urllib.parse.unquote_plus(event["Records"][0]["s3"]["object"]["key"])
        user_id, file_name = key.split("/", 1)

        document_id = shortuuid.uuid()
        conversation_id = shortuuid.uuid()
        now = datetime.now(local_timezone)
        timestamp = (
            now.strftime("%Y-%m-%d_%H-%M-%S_%f_UTC%z")
            .replace("+", "plus")
            .replace(":", "")
        )
       
        # Download and read file
        local_path = f"/tmp/{file_name}"
        s3.download_file(BUCKET, key, local_path)

        with open(local_path, "rb") as f:
            reader = PyPDF2.PdfReader(f)
            pages = str(len(reader.pages))

        document = {
            "userid": user_id,
            "documentid": document_id,
            "filename": file_name,
            "created": timestamp,
            "pages": pages,
            "filesize": str(event["Records"][0]["s3"]["object"]["size"]),
            "docstatus": "UPLOADED",
            "conversations": [
                {"conversationid": conversation_id, "created": timestamp}
            ],
        }

        memory = {"SessionId": conversation_id, "History": []}
        message = {
            "documentid": document_id,
            "key": key,
            "user": user_id,
        }

        # Save to DynamoDB
        document_table.put_item(Item=document)
        memory_table.put_item(Item=memory)

        # Send to SQS
        sqs.send_message(QueueUrl=QUEUE, MessageBody=json.dumps(message))

        logger.info("Upload processed successfully", extra={"document_id": document_id})
        return {"statusCode": 200, "body": "Upload handled"}

    except Exception as e:
        logger.exception("Upload processing failed")
        return {"statusCode": 500, "body": str(e)}
