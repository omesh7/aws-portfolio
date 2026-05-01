# Static Site — S3 + CloudFront + Terraform

Production-ready static website hosting on AWS with S3, CloudFront CDN, and optional Cloudflare DNS. Fully automated via Terraform and GitHub Actions.

## Architecture

```
                 ┌──────────────┐
                 │  Cloudflare  │  (Optional DNS / SSL)
                 └──────┬───────┘
                        │
                 ┌──────▼───────┐
                 │  CloudFront  │  CDN + HTTPS + OAC
                 └──────┬───────┘
                        │
                 ┌──────▼───────┐
                 │   S3 Bucket  │  Private — origin-only access
                 └──────────────┘
                        ▲
                 ┌──────┴───────┐
                 │  Vite + React│  Built in CI or locally
                 └──────────────┘
```

## Key Features

- **IaC**: All infrastructure managed by Terraform (S3, CloudFront, ACM, OAC).
- **CI/CD**: GitHub Actions workflow — build → upload → invalidate cache.
- **Security**: Origin Access Control, HTTPS-only, security headers.
- **Cost**: ~$2-5/month (serverless, pay-per-request).

## Quick Start

```bash
cd infrastructure
cp secrets.auto.tfvars.example secrets.auto.tfvars
# Edit with your AWS region, domain, etc.

terraform init
terraform apply
```

Deploy the site:

```bash
cd ../site && npm install && npm run build
./deploy-local.sh
```

## Terraform Variables

| Variable | Description | Default |
|---|---|---|
| `project_name` | Resource name prefix | `01-static-website-aws-portfolio` |
| `aws_region` | AWS region | `ap-south-1` |
| `environment` | `local` or `ci` | `local` |
| `enable_custom_domain` | Cloudflare integration | `false` |

## CI/CD

GitHub Actions workflow triggers on push. Required secrets:

- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
- `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ZONE_ID` (optional)

## Cleanup

```bash
cd infrastructure && terraform destroy
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*