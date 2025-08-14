import boto3
from botocore.config import Config
import shortuuid
from ..utils import get_user_id, logger, SOUTH_REGION, BUCKET, response

s3 = boto3.client(
    "s3",
    endpoint_url=f"https://s3.{SOUTH_REGION}.amazonaws.com",
    config=Config(
        s3={"addressing_style": "virtual"},
        region_name=SOUTH_REGION,
        signature_version="s3v4",
    ),
)


def s3_key_exists(bucket, key):
    try:
        s3.head_object(Bucket=bucket, Key=key)
        return True
    except:
        return False



def handler(event):
    user_id = get_user_id(event)
    file_name_full = event["queryStringParameters"]["file_name"]
    file_name = file_name_full.split(".pdf")[0]

    exists = s3_key_exists(BUCKET, f"{user_id}/{file_name_full}/{file_name_full}")

    logger.info(
        {
            "user_id": user_id,
            "file_name_full": file_name_full,
            "file_name": file_name,
            "exists": exists,
        }
    )

    if exists:
        suffix = shortuuid.ShortUUID().random(length=4)
        key = f"{user_id}/{file_name}-{suffix}.pdf/{file_name}-{suffix}.pdf"
    else:
        key = f"{user_id}/{file_name}.pdf/{file_name}.pdf"

    presigned_url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": BUCKET,
            "Key": key,
            "ContentType": "application/pdf",
        },
        ExpiresIn=300,
        HttpMethod="PUT",
    )

    return response({"presignedurl": presigned_url})
