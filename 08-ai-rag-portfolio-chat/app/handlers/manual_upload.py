from typing import Dict, Any
import json
import base64
import shortuuid
from datetime import datetime
from utils import logger, s3, document_table, memory_table, QUEUE, sqs, BUCKET


@logger.inject_lambda_context(log_event=True)
def handler(event: Dict[str, Any]) -> Dict[str, Any]:
    try:
        user_id = event["requestContext"]["http"]["sourceIp"]
        body = json.loads(event["body"])
        filename = body["filename"]
        file_data = base64.b64decode(body["file_data"])  # PDF sent as base64

        key = f"{user_id}/{filename}"
        local_path = f"/tmp/{filename}"

        with open(local_path, "wb") as f:
            f.write(file_data)

        # Upload to S3
        s3.upload_file(local_path, BUCKET, key)

        # Trigger message manually (same as S3 event)
        document_id = shortuuid.uuid()
        conversation_id = shortuuid.uuid()
        timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")

        document = {
            "userid": user_id,
            "documentid": document_id,
            "filename": filename,
            "created": timestamp,
            "pages": "unknown",
            "filesize": str(len(file_data)),
            "docstatus": "UPLOADED",
            "conversations": [
                {"conversationid": conversation_id, "created": timestamp}
            ],
        }

        document_table.put_item(Item=document)
        memory_table.put_item(Item={"SessionId": conversation_id, "History": []})

        message = {"documentid": document_id, "key": key, "user": user_id}
        sqs.send_message(QueueUrl=QUEUE, MessageBody=json.dumps(message))

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Document uploaded and queued",
                "document_id": document_id,
                "conversation_id": conversation_id
            }),
        }

    except Exception as e:
        logger.exception("Manual upload failed")
        return {"statusCode": 500, "body": str(e)}
