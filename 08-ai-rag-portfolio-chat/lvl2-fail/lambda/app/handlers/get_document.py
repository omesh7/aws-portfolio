from app.utils import response, get_path_param
from ..utils import get_user_id, logger, document_table, memory_table



def handler(event):
    try:
        user_id = get_user_id(event)
        document_id = get_path_param(event, "documentid")
        conversation_id = get_path_param(event, "conversationid")

        doc_resp = document_table.get_item(
            Key={"userid": user_id, "documentid": document_id}
        )
        document = doc_resp.get("Item", {})

        if not document:
            return response({"error": "Document not found"}, 404)

        document["conversations"] = sorted(
            document.get("conversations", []),
            key=lambda x: x.get("created", ""),
            reverse=True,
        )

        mem_resp = memory_table.get_item(Key={"SessionId": conversation_id})
        messages = mem_resp.get("Item", {}).get("History", [])

        return response(
            {
                "conversationid": conversation_id,
                "document": document,
                "messages": messages,
            }
        )

    except Exception as e:
        logger.exception("Error in get_document")
        return response({"error": str(e)}, 500)
