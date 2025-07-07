import os
import boto3
import uuid
import logging
import tempfile

from langchain_community.embeddings import BedrockEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_community.document_loaders import (
    PyPDFLoader,
    TextLoader,
    UnstructuredMarkdownLoader,
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
    elif ext == ".md":
        return UnstructuredMarkdownLoader(file_path)
    else:
        raise ValueError(f"Unsupported file extension: {ext}")


def split_text(pages, chunk_size=1000, chunk_overlap=200):
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size, chunk_overlap=chunk_overlap
    )
    return splitter.split_documents(pages)


def save_faiss_index(documents, request_id):
    index = FAISS.from_documents(documents, bedrock_embeddings)
    with tempfile.TemporaryDirectory() as tmpdir:
        index.save_local(index_name=request_id, folder_path=tmpdir)
        s3_client.upload_file(
            Filename=os.path.join(tmpdir, request_id + ".faiss"),
            Bucket=BUCKET_NAME,
            Key=f"indices/{request_id}.faiss",
        )
        s3_client.upload_file(
            Filename=os.path.join(tmpdir, request_id + ".pkl"),
            Bucket=BUCKET_NAME,
            Key=f"indices/{request_id}.pkl",
        )


# ----------------------------
# 5. Lambda Handler
# ----------------------------
def lambda_handler(event, context):
    try:
        logger.info("Event received: %s", event)

        record = event["Records"][0]
        s3_bucket = record["s3"]["bucket"]["name"]
        s3_key = record["s3"]["object"]["key"]

        if not s3_key.startswith("docs/"):
            logger.warning("Skipped file not in docs/: %s", s3_key)
            return {"status": "skipped", "reason": "File not in docs/"}

        ext = os.path.splitext(s3_key)[1].lower()
        if ext not in [".pdf", ".txt", ".md"]:
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

        save_faiss_index(chunks, request_id)
        logger.info("Vector index saved and uploaded to S3")

        return {
            "status": "success",
            "chunks": len(chunks),
            "key_base": f"indices/{request_id}",
        }

    except Exception as e:
        logger.error("Error processing file: %s", str(e), exc_info=True)
        return {"status": "error", "error": str(e)}
