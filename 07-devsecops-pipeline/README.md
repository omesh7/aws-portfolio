# DevSecOps Pipeline — Shift-Left Security + ECS Fargate

Production-grade DevSecOps CI/CD pipeline with automated security scanning (Trivy, Checkov, OWASP), multi-stage Docker builds, OIDC-based AWS auth, and serverless deployment to ECS Fargate.

## Pipeline Architecture

```
Source Code
    │
    ▼
┌─────────────────────────────────────────────┐
│  Job 1: Security Scan                       │
│  ├── Trivy FS Scan (source code)            │
│  ├── Checkov (Terraform / IaC)              │
│  ├── OWASP Dependency Check (SCA)           │
│  ├── Trivy Image Scan (Docker)              │
│  └── Upload SARIF → GitHub Security Tab     │
└──────────────┬──────────────────────────────┘
               │ Pass if no Critical/High
               ▼
┌─────────────────────────────────────────────┐
│  Job 2: Build & Push                        │
│  ├── Authenticate via OIDC (no static keys) │
│  ├── Build multi-stage Docker image         │
│  └── Push to Amazon ECR (sha + latest)      │
└──────────────┬──────────────────────────────┘
               ▼
┌─────────────────────────────────────────────┐
│  Job 3: Deploy                              │
│  ├── Update ECS Fargate task definition     │
│  └── Force new deployment                   │
└─────────────────────────────────────────────┘
```

## Key Features

- **Shift-Left Security**: 4 security scanners in CI — code, IaC, dependencies, and container image.
- **OIDC Auth**: GitHub Actions assumes AWS IAM role — no long-lived credentials.
- **SARIF Integration**: Scan results appear in GitHub's Security tab.
- **Multi-Stage Docker**: Minimized final image size.
- **Terraform IaC**: ECR + ECS cluster provisioned as code.
- **Makefile**: `make scan`, `make build`, `make deploy` for local workflows.

## Project Structure

```
├── app/
│   ├── Dockerfile               # Multi-stage production build
│   ├── app.py                   # Application code
│   └── requirements.txt
├── infrastructure/
│   ├── main.tf                  # ECR + ECS Fargate
│   └── variables.tf
├── .checkov.yml                 # Checkov scan configuration
├── Makefile                     # Local dev commands
└── .github/workflows/
    └── devsecops.yml            # Full pipeline definition
```

## Quick Start

```bash
# Provision infrastructure
cd infrastructure
terraform init && terraform apply

# Local security scan
make scan

# Local build
make build
```

## GitHub Secrets Required

| Secret | Purpose |
|---|---|
| `AWS_ROLE_ARN` | IAM role for OIDC assumption |
| `AWS_REGION` | Target AWS region |
| `ECR_REPOSITORY` | ECR repository name |

## Security Gates

| Scanner | Target | Fail Criteria |
|---|---|---|
| Trivy FS | Source code | Critical or High CVEs |
| Checkov | Terraform / IaC | Non-Low violations |
| OWASP | `package.json` deps | Known CVEs |
| Trivy Image | Docker image | Critical or High CVEs |

## Cleanup

```bash
cd infrastructure && terraform destroy
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*
