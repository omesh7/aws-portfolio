from fastapi import FastAPI, Request
import boto3
import json

app = FastAPI()
kinesis = boto3.client("kinesis", region_name="ap-south-1")

@app.post("/send")
async def send_event(request: Request):
    body = await request.json()
    kinesis.put_record(
        StreamName="anomaly-stream",
        Data=json.dumps(body),
        PartitionKey="partition-key"
    )
    return {"status": "sent", "payload": body}
