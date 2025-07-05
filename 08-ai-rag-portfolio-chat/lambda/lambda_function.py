import os
import json
import logging

import boto3
from botocore.exceptions import ClientError
from langchain_aws import BedrockEmbeddings
from langchain_postgres import PGVector
from langchain.chat_models import bedrock
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import create_retrieval_chain, create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate

# ————————— Globals & Clients —————————
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

rds_client = boto3.client("rds-data")
bedrock_client = boto3.client("bedrock-runtime")
s3_client = boto3.client("s3")

# ————————— Env Variables —————————
EMBED_MODEL = os.getenv("EMBED_MODEL")
CHAT_MODEL = os.getenv("CHAT_MODEL")
DB_SECRET_ARN = os.getenv("DB_SECRET_ARN")
DB_CLUSTER_ARN = os.getenv("DB_CLUSTER_ARN")
DB_NAME = os.getenv("DB_NAME")
DB_SCHEMA = os.getenv("DB_SCHEMA")
DB_TABLE = os.getenv("DB_TABLE")

required_env = [
    EMBED_MODEL,
    CHAT_MODEL,
    DB_CLUSTER_ARN,
    DB_SECRET_ARN,
    DB_NAME,
    DB_SCHEMA,
    DB_TABLE,
]
if not all(required_env):
    missing = [
        name
        for name, val in zip(
            [
                "EMBED_MODEL",
                "CHAT_MODEL",
                "DB_CLUSTER_ARN",
                "DB_SECRET_ARN",
                "DB_NAME",
                "DB_SCHEMA",
                "DB_TABLE",
            ],
            required_env,
        )
        if not val
    ]
    raise RuntimeError(f"Missing ENV vars: {', '.join(missing)}")


# ————————— LangChain Setup —————————
embedder = BedrockEmbeddings(model=EMBED_MODEL, client=bedrock_client)
vectorstore = PGVector(
    embeddings=embedder,
    client=rds_client,
    cluster_arn=DB_CLUSTER_ARN,
    secret_arn=DB_SECRET_ARN,
    database=DB_NAME,
    schema=DB_SCHEMA,
    table=DB_TABLE,
)

prompt = ChatPromptTemplate.from_messages(
    [
        ("system", "Answer based on context. If unknown, say you don't know."),
        ("human", "{input}"),
    ]
)


retriever = vectorstore.as_retriever(k=3)
qa_chain = create_retrieval_chain(
    llm=bedrock.BedrockChat(model=CHAT_MODEL, client=bedrock_client),
    retriever=retriever,
)


# ————————— Lambda Handler —————————
def lambda_handler(event, context):
    try:
        # Chat mode
        if "query" in event:
            logger.info("Chat request")
            resp = qa_chain.invoke({"input": event["query"]})
            logger.info("Chat response ready")
            return {"answer": resp["output"]}

        # Ingest mode: S3 trigger
        for rec in event.get("Records", []):
            bucket = rec["s3"]["bucket"]["name"]
            key = rec["s3"]["object"]["key"]
            logger.info(f"Ingesting s3://{bucket}/{key}")
            data = s3_client.get_object(Bucket=bucket, Key=key)["Body"].read().decode()
            chunks = RecursiveCharacterTextSplitter(
                chunk_size=1000, chunk_overlap=200
            ).split_text(data)
            logger.info(f"Chunked into {len(chunks)}")
            vectorstore.add_texts(chunks, [{"source": key}] * len(chunks))
            logger.info("Ingested into vector store")
        return {"status": "ingest done"}
    except ClientError as e:
        logger.error("AWS ClientError", exc_info=True)
        return {"error": str(e)}
    except Exception as e:
        logger.error("Unexpected error", exc_info=True)
        return {"error": str(e)}
