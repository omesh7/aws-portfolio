import urllib
import shortuuid
import PyPDF2
from datetime import datetime, timezone
import json
import base64
from zoneinfo import ZoneInfo
from ..utils import (
    logger,
    document_table,
    memory_table,
    s3,
    BUCKET,
    sqs,
    QUEUE,
)

local_timezone = ZoneInfo("Asia/Kolkata")  # Replace with your actual timezone


def parse_multipart_data(event):
    content_type = event["headers"].get("Content-Type") or event["headers"].get(
        "content-type"
    )
    if not content_type:
        raise ValueError("Content-Type header missing")

    parts = content_type.split(";")
    params = {}
    for part in parts[1:]:
        if "=" in part:
            key, value = part.strip().split("=", 1)
            params[key] = value

    if "boundary" not in params:
        raise ValueError("Missing 'boundary' in Content-Type header")

    boundary = params["boundary"]
    boundary_bytes = bytes(f"--{boundary}", "utf-8")

    body = event.get("body", "")
    if event.get("isBase64Encoded", False):
        body = base64.b64decode(body)
    else:
        body = body.encode("utf-8")

    parts = body.split(boundary_bytes)

    fields = {}
    for part in parts:
        if not part or part == b"--\r\n" or part == b"--":
            continue
        if part.startswith(b"\r\n"):
            part = part[2:]
        header_end = part.find(b"\r\n\r\n")
        if header_end == -1:
            continue
        headers_part = part[:header_end].decode("utf-8")
        content_part = part[header_end + 4 : -2]

        content_disposition = None
        for header_line in headers_part.split("\r\n"):
            if header_line.lower().startswith("content-disposition"):
                content_disposition = header_line
                break
        if not content_disposition:
            continue

        disposition_parts = content_disposition.split(";")
        disposition_dict = {}
        for disp_part in disposition_parts[1:]:
            if "=" in disp_part:
                k, v = disp_part.strip().split("=", 1)
                disposition_dict[k] = v.strip('"')

        field_name = disposition_dict.get("name")
        if not field_name:
            continue

        filename = disposition_dict.get("filename")
        if filename:
            fields[field_name] = {"filename": filename, "content": content_part}
        else:
            fields[field_name] = content_part.decode("utf-8")

    return fields


def handler(event):
    logger.info("Manual upload triggered", extra={"event": event})
    try:
        fields = parse_multipart_data(event)

        # Expecting fields: 'user_id' and 'file' (file input name)
        user_id = fields.get("user_id")
        if not user_id:
            raise ValueError("Missing user_id field")

        file_field = fields.get("file")
        if not file_field:
            raise ValueError("No file uploaded")

        filename = file_field["filename"]
        content = file_field["content"]

        document_id = shortuuid.uuid()
        conversation_id = shortuuid.uuid()
        now = datetime.now(local_timezone)
        timestamp = (
            now.strftime("%Y-%m-%d_%H-%M-%S_%f_UTC%z")
            .replace("+", "plus")
            .replace(":", "")
        )

        # Upload file content to S3
        s3_key = f"uploads/{filename}"
        s3.put_object(Bucket=BUCKET, Key=s3_key, Body=content)

        # Save file temporarily to read PDF metadata
        import tempfile

        with tempfile.NamedTemporaryFile(delete=True) as tmp_file:
            tmp_file.write(content)
            tmp_file.flush()
            reader = PyPDF2.PdfReader(tmp_file.name)
            pages = str(len(reader.pages))

        filesize = str(len(content))

        document = {
            "userid": user_id,
            "documentid": document_id,
            "filename": filename,
            "created": timestamp,
            "pages": pages,
            "filesize": filesize,
            "docstatus": "UPLOADED",
            "conversations": [
                {"conversationid": conversation_id, "created": timestamp}
            ],
        }

        memory = {"SessionId": conversation_id, "History": []}
        message = {"documentid": document_id, "key": s3_key, "user": user_id}

        # Save metadata in DynamoDB
        document_table.put_item(Item=document)
        memory_table.put_item(Item=memory)

        # Send message to SQS
        sqs.send_message(QueueUrl=QUEUE, MessageBody=json.dumps(message))

        logger.info(
            "Manual upload processed successfully", extra={"document_id": document_id}
        )

        return {"statusCode": 200, "body": "Upload successful"}

    except Exception as e:
        logger.exception("Manual upload failed")
        return {"statusCode": 500, "body": str(e)}
