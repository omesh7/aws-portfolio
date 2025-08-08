from utils import (
    get_user_id,
    logger,
    document_table,
    s3,
    BUCKET,
    memory_table,
    response as stdresponse,
)


@logger.inject_lambda_context(log_event=True)
def handler(event):
    user_id = get_user_id(event)
    document_id = event["pathParameters"]["documentid"]

    response = document_table.get_item(
        Key={"userid": user_id, "documentid": document_id}
    )
    document = response["Item"]
    logger.info({"document": document})
    logger.info("Deleting DDB items")
    with memory_table.batch_writer() as batch:
        for item in document["conversations"]:
            batch.delete_item(Key={"SessionId": item["conversationid"]})

    document_table.delete_item(Key={"userid": user_id, "documentid": document_id})

    logger.info("Deleting S3 objects")
    filename = document["filename"]
    objects = [
        {"Key": f"{user_id}/{filename}/{key}"}
        for key in [filename, "index.faiss", "index.pkl"]
    ]
    response = s3.delete_objects(
        Bucket=BUCKET,
        Delete={
            "Objects": objects,
            "Quiet": True,
        },
    )
    logger.info({"Response": response})

    return stdresponse({}, status_code=204)
