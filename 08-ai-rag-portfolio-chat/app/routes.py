from typing import Dict, Any
from app.handlers import (
    add_conversation,
    generate_presigned_url,
    generate_response,
    get_document,
    manual_upload,
)


def handle_route(path: str, method: str, event: Dict[str, Any]) -> Dict[str, Any]:
    if path == "/document" and method == "GET":
        return get_document.handler(event)

    elif path == "/conversation" and method == "POST":
        return add_conversation.handler(event)

    elif path == "/upload" and method == "POST":
        return manual_upload.handler(event)

    elif path == "/presign-url" and method == "GET":
        return generate_presigned_url.handler(event)

    elif path.startswith("/chat/") and method == "POST":
        conversation_id = path.split("/chat/")[1]
        event["pathParameters"] = {"conversationid": conversation_id}
        return generate_response.handler(event)

    else:
        return {"statusCode": 404, "body": f"Route not found: {method} {path}"}
