# N8N Automation Platform Deployment

Deploy n8n workflow automation platform on AWS with custom domain and SSL.

## Architecture

- **AWS ECS Fargate** - Containerized n8n deployment
- **Application Load Balancer** - HTTPS termination with ACM certificate
- **RDS PostgreSQL** - Database for n8n workflows
- **Cloudflare DNS** - Domain management and SSL validation

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Cloudflare account with domain
- Domain managed by Cloudflare

## Setup

1. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Get Cloudflare credentials**:
   - Zone ID: Cloudflare Dashboard > Domain > Overview
   - API Token: Cloudflare Dashboard > My Profile > API Tokens

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Required Variables

- `n8n_hostname` - Your custom domain (e.g., n8n.yourdomain.com)
- `cloudflare_zone_id` - Cloudflare zone ID
- `cloudflare_api_token` - Cloudflare API token

### Optional Variables

- `aws_region` - AWS region (default: us-east-1)
- `prefix` - Resource naming prefix (default: n8n-portfolio)

## Debugging

### Common Issues

1. **Certificate validation fails**:
   ```bash
   # Check DNS records
   dig TXT _acme-challenge.n8n.yourdomain.com
   ```

2. **Module not found**:
   ```bash
   terraform init -upgrade
   ```

3. **Load balancer health checks fail**:
   - Ensure Cloudflare proxy is disabled for ALB
   - Check security group rules

### Verification

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn <cert-arn>

# Test n8n endpoint
curl -I https://n8n.yourdomain.com
```

## Cleanup

```bash
terraform destroy
```

## Outputs

- `n8n_url` - Access URL for n8n instance
- `load_balancer_dns` - Direct ALB DNS name