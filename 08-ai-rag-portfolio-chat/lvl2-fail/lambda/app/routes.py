from typing import Dict, Any
from .handlers import (
    add_conversation,
    generate_presigned_url,
    generate_response,
    get_document,
    manual_upload,
    get_document,
    get_all_documents,
)

import logging

logging.basicConfig(level=logging.INFO)


def handle_route(path, method, event, context):
    logging.info(f"Incoming request - Method: {method}, Path: {path}, Event: {event}")

    if path == "/document" and method == "GET":
        logging.info("Matched route: GET /document")
        return get_document.handler(event)

    elif path == "/conversation" and method == "    ":
        logging.info("Matched route: POST /conversation")
        return add_conversation.handler(event)

    elif path == "/upload" and method == "POST":
        logging.info("Matched route: POST /upload")
        return manual_upload.handler(event)

    elif path == "/presign-url" and method == "GET":
        logging.info("Matched route: GET /presign-url")
        return generate_presigned_url.handler(event)

    elif path.startswith("/chat/") and method == "POST":
        conversation_id = path.split("/chat/")[1]
        logging.info(f"Matched route: POST /chat/{conversation_id}")
        event["pathParameters"] = {"conversationid": conversation_id}
        return generate_response.handler(event)

    elif path.startswith("/doc") and method == "GET":
        parts = path.split("/doc/")
        doc_id = parts[1] if len(parts) > 1 else None
        if doc_id == "all" or not doc_id:
            logging.info("Matched route: GET /doc/all")
            return get_all_documents.handler(event)
        else:
            logging.info(f"Matched route: GET /doc/{doc_id}")
            return get_document.handler(event)

    else:
        logging.warning(f"No matching route found for {method} {path}")
        return {"statusCode": 404, "body": f"Route not found: {method} {path}"}
