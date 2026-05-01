# FinOps Cost Optimizer

> Automated EC2 cost scheduling + AWS Cost Anomaly Detection alerting — built with Terraform, Lambda (Python), EventBridge, and SNS.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│  ┌──────────────┐      ┌─────────────────┐    ┌─────────────┐  │
│  │ EventBridge  │─────▶│  EC2 Scheduler  │───▶│  EC2        │  │
│  │ (every 5min) │      │  Lambda (Python) │    │  Instances  │  │
│  └──────────────┘      │                 │    │  [tagged]   │  │
│                        │  reads tags:    │    └─────────────┘  │
│                        │  AutoSchedule   │                     │
│                        └────────┬────────┘                     │
│                                 │ stop/start actions           │
│                                 ▼                              │
│                        ┌─────────────────┐                     │
│                        │   SNS: alerts   │──▶ 📧 Email         │
│                        └─────────────────┘                     │
│                                                                 │
│  ┌──────────────────────┐    ┌──────────────────┐              │
│  │ AWS Cost Anomaly     │───▶│ SNS: raw anomaly │              │
│  │ Detection Monitor    │    └────────┬─────────┘              │
│  └──────────────────────┘            │                         │
│                                      ▼                         │
│                             ┌─────────────────────┐            │
│                             │  Cost Reporter      │            │
│                             │  Lambda (Python)    │            │
│                             │  - enriches alert   │            │
│                             │  - fetches top 10   │            │
│                             │    services by cost │            │
│                             └──────────┬──────────┘            │
│                                        │                       │
│                                        ▼                       │
│                               ┌─────────────────┐             │
│                               │  SNS: alerts    │──▶ 📧 Email │
│                               └─────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

---

## What This Does

### 1. EC2 Auto-Scheduler (Cost Saver)
Tags EC2 instances with a schedule — the Lambda stops them outside business hours and starts them back up automatically.

**Tag an instance:**
```
Key:   AutoSchedule
Value: start=08:00;stop=20:00;tz=Asia/Kolkata;days=Mon-Fri
```

This alone can cut EC2 costs by **60–70%** for dev/test environments that don't need to run 24/7.

### 2. Cost Anomaly Detection + Enriched Alerts
AWS Cost Anomaly Detection monitors your account spend. When an anomaly exceeds the configured threshold (default: $10), it:
1. Fires to a raw SNS topic
2. Lambda intercepts, fetches top 10 services from Cost Explorer
3. Publishes a human-readable enriched alert to email

No more discovering $300 surprise bills at month-end.

---

## Files

```
11-finops-cost-optimizer/
├── src/lambda/
│   ├── scheduler.py              # EC2 start/stop based on AutoSchedule tag
│   └── cost_anomaly_reporter.py  # Enriches Cost Anomaly alerts with context
├── terraform/
│   ├── provider.tf               # AWS provider + S3 backend
│   ├── variables.tf              # All input variables
│   ├── lambda.tf                 # Lambda functions + log groups
│   ├── iam.tf                    # Least-privilege IAM roles
│   ├── eventbridge.tf            # EventBridge rule (cron trigger)
│   ├── sns.tf                    # SNS topics + Cost Anomaly Detection
│   ├── outputs.tf                # Key resource ARNs
│   └── terraform.tfvars.example  # Sample config (copy → terraform.tfvars)
├── scripts/
│   └── destroy.sh                # Safe teardown script
└── .github/workflows/
    └── deploy.yml                # CI/CD: lint → Checkov → plan/apply via OIDC
```

---

## Quick Start

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.5
- S3 bucket for remote state

### 1. Clone & configure

```bash
cd 11-finops-cost-optimizer/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your alert_email and preferences
```

### 2. Deploy

```bash
terraform init \
  -backend-config="bucket=YOUR-STATE-BUCKET" \
  -backend-config="key=finops-cost-optimizer/terraform.tfstate" \
  -backend-config="region=ap-south-1"

terraform plan
terraform apply
```

### 3. Tag your dev instances

Add this tag to any EC2 instance you want auto-scheduled:

| Key | Value |
|-----|-------|
| `AutoSchedule` | `start=09:00;stop=21:00;tz=Asia/Kolkata;days=Mon-Fri` |

### 4. Test the scheduler (dry run)

```bash
# Invoke Lambda manually with dry run
aws lambda invoke \
  --function-name finops-cost-optimizer-ec2-scheduler-dev \
  --payload '{}' \
  response.json && cat response.json
```

### 5. Tear down

```bash
./scripts/destroy.sh
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| **Separate SNS topics** | Raw anomaly topic is internal; alerts topic is subscriber-facing. Keeps the enrichment layer independent. |
| **Tag-based scheduling** | No central config file to maintain. Each instance declares its own schedule. Scales to 0 or 1000 instances without code changes. |
| **OIDC in CI/CD** | No long-lived IAM access keys stored in GitHub Secrets. Uses GitHub's OIDC token for short-lived AWS credentials. |
| **Least-privilege IAM** | Scheduler Lambda can only start/stop instances — not terminate, create, or modify. |
| **Dry run mode** | `DRY_RUN=true` env var lets you validate the scheduler logic without touching any instances. |
| **Checkov in pipeline** | IaC security scanning on every push — catches misconfigured IAM, missing encryption, public S3 buckets before deployment. |

---

## Cost Impact

| Scenario | Estimated Saving |
|---|---|
| 3x `t3.medium` dev instances running 24/7 → 12hr/day weekdays only | ~65% reduction (~$35/month → ~$12/month) |
| Catching a runaway Lambda/Kinesis anomaly early | Potentially hundreds of dollars |
| Cost Anomaly alert threshold: $10 | First line of defense against billing surprises |

---

## CI/CD Secrets Required

| Secret | Value |
|---|---|
| `AWS_ROLE_ARN` | IAM role ARN with OIDC trust for GitHub Actions |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform remote state |
| `ALERT_EMAIL` | Email address for cost/scheduler notifications |

---

## Technologies Used

`Terraform` `AWS Lambda (Python 3.12)` `Amazon EventBridge` `AWS Cost Anomaly Detection` `Amazon SNS` `AWS Cost Explorer` `Amazon CloudWatch` `GitHub Actions` `OIDC` `Checkov`
