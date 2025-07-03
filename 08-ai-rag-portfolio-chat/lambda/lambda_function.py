import os
import boto3
import json
from lance import LanceDB
import numpy as np

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = os.getenv('S3_BUCKET')
    key    = os.getenv('S3_KEY', 'readmes/README.md')
    local_path = '/tmp/sample.md'
    s3.download_file(bucket, key, local_path)

    # simple paragraph chunks
    with open(local_path, 'r', encoding='utf-8') as f:
        chunks = [c for c in f.read().split('\n\n') if c.strip()]

    db = LanceDB('/tmp/lancedb', create=True)
    table = db.create_table('chunks', [{'text': str, 'embedding': 'ndarray<float32>[512]'}])

    for i, c in enumerate(chunks):
        emb = np.zeros(512, dtype='float32')
        emb[i % 512] = len(c)
        table.upsert([{"text": c, "embedding": emb}])

    # query with first chunk embedding
    vec = table.to_pandas()['embedding'][0]
    results = table.search(vec, limit=3).to_pandas()
    return {
        "statusCode": 200,
        "body": json.dumps({"snippets": results["text"].tolist()})
    }
