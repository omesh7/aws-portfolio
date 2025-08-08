from datetime import datetime
import shortuuid
from utils import (
    get_user_id,
    logger,
    document_table,
    memory_table,
    response as stdresponse,
)


@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    user_id = get_user_id(event)  
    document_id = event["pathParameters"]["documentid"]

    response = document_table.get_item(
        Key={"userid": user_id, "documentid": document_id}
    )
    conversations = response["Item"]["conversations"]
    logger.info({"conversations": conversations})

    conversation_id = shortuuid.uuid()
    timestamp = datetime.now(datetime.timezone.utc)
    timestamp_str = timestamp.strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    conversation = {
        "conversationid": conversation_id,
        "created": timestamp_str,
    }
    conversations.append(conversation)
    logger.info({"conversation_new": conversation})
    document_table.update_item(
        Key={"userid": user_id, "documentid": document_id},
        UpdateExpression="SET conversations = :conversations",
        ExpressionAttributeValues={":conversations": conversations},
    )

    conversation = {"SessionId": conversation_id, "History": []}
    memory_table.put_item(Item=conversation)
    return stdresponse({"conversationid": conversation_id})
