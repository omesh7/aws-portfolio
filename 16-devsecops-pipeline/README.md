# 🛡️ Project 16: DevSecOps CI/CD Pipeline

A production-realistic DevSecOps pipeline demonstrating automated security gating, multi-stage container builds, and serverless deployment on AWS ECS Fargate.

## 🏗️ Pipeline Architecture

```ascii
[ Source Code ] 
      |
      v
[ Job 1: Security Scan ] ------------------------------------┐
| - Trivy FS Scan (Code)                                     |
| - Checkov (Terraform/IaC)                                  |
| - OWASP Dependency Check (SCA)                             |
| - Trivy Image Scan (Docker)                                |
| - Upload SARIF to GitHub Security Tab                      |
└----------┬-------------------------------------------------┘
           | (Pass if no Critical/High)
           v
[ Job 2: Build & Push ]
| - Authenticate via OIDC                                    |
| - Build Docker Image                                       |
| - Push to Amazon ECR (sha + latest)                        |
└----------┬-------------------------------------------------┘
           |
           v
[ Job 3: Deploy ]
| - Update ECS Fargate Service                               |
| - Force New Deployment                                     |
└------------------------------------------------------------┘
```

## 🚀 Features

- **Shift-Left Security**: Multiple security scanners integrated into the CI process.
- **Infrastructure as Code**: Terraform modules for ECR and ECS provisioning.
- **Container Orchestration**: Serverless deployment using AWS ECS Fargate.
- **Secure Authentication**: Uses GitHub OIDC to assume AWS IAM Roles (no long-lived secrets).
- **Vulnerability Management**: SARIF reports uploaded directly to GitHub Security dashboard.

## 🛠️ Setup Instructions

### 1. Prerequisites
- AWS Account and CLI configured.
- GitHub Repository Secrets configured (see below).
- Terraform installed locally for initial provisioning.

### 2. GitHub Secrets
Add the following secrets to your GitHub repository:
- `AWS_ROLE_ARN`: The IAM Role ARN that GitHub Actions will assume via OIDC.
- `AWS_REGION`: Your target AWS region (e.g., `ap-south-1`).
- `ECR_REPOSITORY`: The name of your ECR repository.

### 3. Initial Provisioning
Run Terraform locally to create the ECR repository and ECS cluster:
```bash
cd infrastructure
terraform init
terraform apply
```

### 4. Local Development
Use the provided `Makefile` for local testing:
```bash
make scan    # Run local security scans
make build   # Build docker image locally
```

## 🛡️ Security Gates
- **Trivy**: Fails if Critical or High vulnerabilities are found in code or image.
- **Checkov**: Validates IaC best practices (ignoring only Low severity).
- **OWASP**: Scans for known vulnerabilities in `package.json` dependencies.

---
*Part of the [AWS Portfolio](https://github.com/omesh7/aws-portfolio)*
