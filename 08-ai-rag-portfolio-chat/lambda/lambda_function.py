import os
import boto3
import uuid
import logging
import tempfile
from langchain_aws import BedrockEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
import numpy as np
import json
from langchain_community.document_loaders import (
    PyPDFLoader,
    TextLoader,
)

# ----------------------------
# 1. Setup Logging
# ----------------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# ----------------------------
# 2. AWS Clients & ENV
# ----------------------------
s3_client = boto3.client("s3")
bedrock_client = boto3.client(service_name="bedrock-runtime")

BUCKET_NAME = os.getenv("BUCKET_NAME")
EMBED_MODEL = os.getenv("EMBED_MODEL", "amazon.titan-embed-text-v1")

# ----------------------------
# 3. Embedding Model
# ----------------------------
bedrock_embeddings = BedrockEmbeddings(model_id=EMBED_MODEL, client=bedrock_client)

# ----------------------------
# 4. Helper Functions
# ----------------------------


def get_unique_id():
    return str(uuid.uuid4())


def get_loader(file_path: str, ext: str):
    ext = ext.lower()
    if ext == ".pdf":
        return PyPDFLoader(file_path)
    elif ext == ".txt":
        return TextLoader(file_path)
    else:
        raise ValueError(f"Unsupported file extension: {ext}")


def split_text(pages, chunk_size=1000, chunk_overlap=200):
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size, chunk_overlap=chunk_overlap
    )
    return splitter.split_documents(pages)


def save_vector_index(documents, request_id):
    # Create simple vector index
    vectors = []
    texts = []
    
    for doc in documents:
        embedding = bedrock_embeddings.embed_query(doc.page_content)
        vectors.append(embedding)
        texts.append({
            "content": doc.page_content,
            "metadata": doc.metadata
        })
    
    # Save to S3 as JSON
    index_data = {
        "vectors": vectors,
        "texts": texts
    }
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(index_data, f)
        temp_file = f.name
    
    s3_client.upload_file(
        Filename=temp_file,
        Bucket=BUCKET_NAME,
        Key=f"indices/{request_id}.json"
    )
    
    os.unlink(temp_file)


# ----------------------------
# 5. Lambda Handler
# ----------------------------
def lambda_handler(event, context):
    try:
        logger.info("Event received: %s", event)

        # Handle S3 event
        if "Records" in event:
            record = event["Records"][0]
            s3_bucket = record["s3"]["bucket"]["name"]
            s3_key = record["s3"]["object"]["key"]
        # Handle direct invocation with bucket/key
        elif "bucket" in event and "key" in event:
            s3_bucket = event["bucket"]
            s3_key = event["key"]
        # Handle manual trigger with s3Bucket/s3Key
        elif "s3Bucket" in event and "s3Key" in event:
            s3_bucket = event["s3Bucket"]
            s3_key = event["s3Key"]
        # Handle API Gateway body
        elif "body" in event:
            import json
            body = json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
            s3_bucket = body.get("bucket") or body.get("s3Bucket") or BUCKET_NAME
            s3_key = body["key"] if "key" in body else body["s3Key"]
        else:
            raise ValueError("Invalid event format. Expected: S3 event, {bucket,key}, {s3Bucket,s3Key}, or API Gateway body.")

        # Use provided bucket or default
        if not s3_bucket:
            s3_bucket = BUCKET_NAME
            
        if not s3_key.startswith("docs/"):
            logger.warning("Skipped file not in docs/: %s", s3_key)
            return {"status": "skipped", "reason": "File not in docs/"}

        ext = os.path.splitext(s3_key)[1].lower()
        if ext not in [".pdf", ".txt"]:
            logger.warning("Unsupported file type: %s", s3_key)
            return {"status": "skipped", "reason": f"Unsupported extension: {ext}"}

        request_id = get_unique_id()
        tmp_file = f"/tmp/{request_id}{ext}"

        logger.info("Downloading file from S3: %s", s3_key)
        s3_client.download_file(Bucket=s3_bucket, Key=s3_key, Filename=tmp_file)

        loader = get_loader(tmp_file, ext)
        pages = loader.load_and_split()
        logger.info("Loaded %d pages from document", len(pages))

        chunks = split_text(pages)
        logger.info("Split into %d chunks", len(chunks))

        save_vector_index(chunks, request_id)
        logger.info("Vector index saved and uploaded to S3")

        return {
            "status": "success",
            "chunks": len(chunks),
            "index_key": f"indices/{request_id}.json",
        }

    except Exception as e:
        logger.error("Error processing file: %s", str(e), exc_info=True)
        return {"status": "error", "error": str(e)}
