from typing import Dict, Any
import json
import boto3
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from utils import (
    logger,
    s3,
    BUCKET,
    EMBEDDING_MODEL_ID,
    MEMORY_TABLE,
    MODEL_ID,
    response as stdresponse,
)

from langchain_community.vectorstores import FAISS
from langchain_aws.embeddings import BedrockEmbeddings
from langchain_aws.chat_models import ChatBedrock
from langchain_community.chat_message_histories import DynamoDBChatMessageHistory


@logger.inject_lambda_context(log_event=True)
def handler(event):
    body = json.loads(event["body"])
    user = event["requestContext"]["authorizer"]["claims"]["sub"]
    file_name = body["fileName"]
    human_input = body["prompt"]
    conversation_id = event["pathParameters"]["conversationid"]

    # Download FAISS index
    local_dir = "/tmp"
    s3.download_file(
        BUCKET, f"{user}/{file_name}/index.faiss", f"{local_dir}/index.faiss"
    )
    s3.download_file(BUCKET, f"{user}/{file_name}/index.pkl", f"{local_dir}/index.pkl")

    embeddings = BedrockEmbeddings(
        model_id=EMBEDDING_MODEL_ID,
        client=boto3.client("bedrock-runtime"),
        region_name="us-east-1",
    )
    faiss_index = FAISS.load_local(
        local_dir, embeddings, allow_dangerous_deserialization=True
    )

    message_history = DynamoDBChatMessageHistory(
        table_name=MEMORY_TABLE, session_id=conversation_id
    )

    # Prompt to convert follow-up questions into standalone queries
    contextualize_prompt = ChatPromptTemplate.from_messages(
        [
            ("system", "Make the follow-up question standalone based on chat history."),
            MessagesPlaceholder(variable_name="chat_history"),
            ("human", "{input}"),
        ]
    )

    history_aware_retriever = create_history_aware_retriever(
        ChatBedrock(model_id=MODEL_ID, model_kwargs={"temperature": 0.0}),
        faiss_index.as_retriever(),
        contextualize_prompt,
    )

    # Prompt for answering using context + history
    qa_prompt = ChatPromptTemplate.from_messages(
        [
            ("system", "Answer using only the retrieved context."),
            MessagesPlaceholder(variable_name="chat_history"),
            ("human", "{input}"),
        ]
    )

    doc_chain = create_stuff_documents_chain(ChatBedrock(model_id=MODEL_ID), qa_prompt)

    chain = create_retrieval_chain(history_aware_retriever, doc_chain)

    result = chain.invoke(
        {"input": human_input, "chat_history": message_history.messages}
    )

    logger.info(f"Response: {result.get('output')}")

    return stdresponse({"answer": result.get("output")})
