# Multi-Cloud Disaster Recovery — AWS + GCP Failover

Serverless weather application with multi-cloud architecture across AWS and Google Cloud. Features automated DNS failover via Cloudflare for zero-downtime disaster recovery.

## Architecture

```
                    ┌──────────────┐
      User ────────►│  Cloudflare  │  DNS + Health Checks
                    └──────┬───────┘
                     ┌─────┴─────┐
              Healthy│           │Failover
                     ▼           ▼
              ┌────────────┐  ┌────────────┐
              │  AWS (Pri.) │  │  GCP (Sec.)│
              │ CloudFront  │  │ Cloud CDN  │
              │ S3 + Lambda │  │ GCS + CF   │
              └────────────┘  └────────────┘
                     │           │
                     └─────┬─────┘
                           ▼
                    OpenWeather API
```

## Key Features

- **Multi-Cloud IaC**: Terraform modules for both AWS and GCP.
- **Automated Failover**: Cloudflare health checks with automatic DNS re-routing.
- **Serverless**: Lambda (AWS) + Cloud Functions (GCP) — no servers to manage.
- **CDN**: CloudFront (AWS) + Cloud CDN (GCP) for global distribution.
- **Cost**: <$5/month at moderate traffic.

## Project Structure

```
├── backend/                     # Serverless functions (Node.js 18)
│   ├── index.js
│   └── package.json
├── frontend/                    # Vanilla JS + CSS3 (no frameworks)
│   ├── index.html
│   ├── script.js
│   └── style.css
├── infrastructure/              # Terraform
│   ├── modules/
│   │   ├── aws/                 # S3, CloudFront, Lambda, ACM
│   │   └── gcp/                 # GCS, Cloud CDN, Cloud Functions
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
├── scripts/linux/               # deploy / destroy / status / test-failover
├── DEPLOYMENT-STRATEGIES.md     # DR strategy documentation
└── terraform.tfvars.example
```

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with API keys and Cloudflare credentials

cd infrastructure
terraform init && terraform apply
```

## Failover Testing

```bash
# Check endpoint health
./scripts/linux/status.sh

# Simulate primary failure and verify DNS switchover
./scripts/linux/test-failover.sh
```

## Enabling GCP Secondary

Uncomment the GCP module in `infrastructure/main.tf`:

```hcl
module "gcp_infrastructure" {
  source = "./modules/gcp"
  # ...
}
```

## Cleanup

```bash
./scripts/linux/destroy.sh
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*