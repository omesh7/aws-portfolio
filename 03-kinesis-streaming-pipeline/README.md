# Real-Time Streaming — Kinesis + ECR + Lambda

Real-time data streaming pipeline using AWS Kinesis for ingestion, containerized producers on ECR, and Lambda consumers for serverless processing. Terraform-managed with remote state.

## Architecture

```
Producer (Docker/ECR)
    │
    ▼
Kinesis Data Stream ──► Lambda Consumer ──► Processing / Analytics
    │
    └──► CloudWatch Metrics & Alarms
```

## Key Features

- **Stream Processing**: Kinesis Data Stream for real-time event ingestion.
- **Containerized Producer**: Docker image stored in ECR, pushes records to Kinesis.
- **Serverless Consumer**: Lambda function processes stream records in batches.
- **Remote State**: S3 + DynamoDB backend for Terraform state locking.
- **IaC**: Modular Terraform for all infrastructure.

## Project Structure

```
├── producer/                    # Dockerized data producer
│   ├── Dockerfile
│   └── producer.py
├── lambda/                      # Stream consumer function
│   └── handler.py
├── infrastructure/              # Terraform (Kinesis, ECR, Lambda, IAM)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── state-file-infra/            # S3 + DynamoDB state backend setup
├── deploy.sh                    # One-command deployment
└── README.md
```

## Quick Start

```bash
# 1. Set up remote state backend
cd state-file-infra
terraform init && terraform apply

# 2. Deploy main infrastructure
cd ../infrastructure
terraform init && terraform apply

# 3. Build and push producer
./deploy.sh
```

## Operations

```bash
# Monitor stream metrics
aws kinesis describe-stream --stream-name <stream-name>

# Check Lambda invocations
aws logs tail /aws/lambda/<function-name> --follow

# Push test records
cd producer && python producer.py
```

## Cleanup

```bash
cd infrastructure && terraform destroy
cd ../state-file-infra && terraform destroy
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*