from utils import get_user_id, logger, document_table, response as stdresponse
from boto3.dynamodb.conditions import Key


@logger.inject_lambda_context(log_event=True)
def handler(event):
    user_id = get_user_id(event)
    response = document_table.query(KeyConditionExpression=Key("userid").eq(user_id))
    items = sorted(response["Items"], key=lambda item: item["created"], reverse=True)
    for item in items:
        item["conversations"] = sorted(
            item["conversations"], key=lambda conv: conv["created"], reverse=True
        )
    logger.info({"items": items})

    return stdresponse(body=items)
