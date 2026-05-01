# CI/CD Pipeline — AWS CodePipeline + ECS Fargate

End-to-end CI/CD pipeline using AWS CodePipeline with dual build stages: a containerized Python Flask API on ECS Fargate and a React frontend on S3. Fully provisioned with Terraform.

## Architecture

```
GitHub Push
    │
    ▼
CodePipeline ──┬── Backend Build ──► Docker ──► ECR ──► ECS Fargate ──► ALB
               │
               └── Frontend Build ──► Vite ──► S3 Static Website
```

## Key Features

- **Dual Pipeline**: Parallel backend (Docker → ECR → ECS) and frontend (Vite → S3) builds.
- **ECS Fargate**: Serverless containers — no EC2 to manage.
- **Terraform IaC**: VPC, ECS cluster, ALB, CodePipeline, ECR — all codified.
- **Grafana Ready**: Pre-configured dashboard for container metrics.
- **Cost**: ~$33-42/month (ECS + ALB + storage).

## Project Structure

```
├── app.py                       # Flask API (2048 game logic)
├── docker/Dockerfile            # Multi-stage container build
├── buildspec/
│   ├── backend-buildspec.yml    # CodeBuild — Docker build & ECR push
│   └── frontend-buildspec.yml   # CodeBuild — React build & S3 sync
├── frontend/                    # React + Vite application
├── infrastructure/              # Terraform (VPC, ECS, ALB, CodePipeline)
├── grafana/                     # Dashboard JSON exports
└── scripts/                     # Deploy / destroy / status helpers
```

## Quick Start

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit with your AWS account details

terraform init && terraform apply
```

The pipeline triggers automatically on `git push`. Manual trigger:

```bash
./scripts/linux/deploy.sh trigger-build
```

## Deployment Verification

```bash
# Check ECS service health
aws ecs describe-services --cluster <cluster> --services <service>

# Tail container logs
aws logs tail "/ecs/project-name" --follow

# Test API
curl http://<ALB-DNS>:8080/
```

## Local Development

```bash
# Backend
pip install -r requirements.txt && python app.py

# Frontend
cd frontend && npm install && npm run dev

# Docker
docker build -f docker/Dockerfile -t 2048-game . && docker run -p 8080:8080 2048-game
```

## Cleanup

```bash
./scripts/linux/destroy.sh
# or
cd infrastructure && terraform destroy
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*
