# 🚀 Deployment Guide - Multi-Cloud Weather Tracker

## Prerequisites

### Required Tools
- [Terraform](https://terraform.io/downloads) (>= 1.0)
- [AWS CLI](https://aws.amazon.com/cli/) (configured with credentials)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (logged in)
- [Cloudflare Account](https://cloudflare.com) with API token
- Domain managed by Cloudflare (omesh.site)

### Required Accounts & Services
- AWS Account with appropriate permissions
- Azure Account with subscription
- Cloudflare account with domain management
- OpenWeatherMap API key (free at openweathermap.org)
- Terraform Cloud account (optional)

## Step-by-Step Deployment

### 1. Configure Cloud Credentials

```bash
# AWS CLI Configuration
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (ap-south-1)

# Azure CLI Login
az login
# Follow browser authentication flow

# Verify credentials
aws sts get-caller-identity
az account show
```

### 2. Setup Cloudflare API Access

1. Login to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to "My Profile" > "API Tokens"
3. Create token with permissions:
   - Zone:Zone:Read
   - Zone:DNS:Edit
   - Zone:Zone Settings:Read
4. Note your Zone ID from the domain overview page

### 3. Clone and Setup Project

```bash
git clone <your-repository>
cd 14-multicloud-weather-tracker
```

### 4. Configure Terraform Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region = "ap-south-1"
azure_location = "East US"
azure_resource_group = "weather-tracker-rg"

# Cloudflare Configuration
cloudflare_api_token = "your_cloudflare_api_token_here"
cloudflare_zone_id = "your_cloudflare_zone_id_here"

# Project Configuration
project_name = "14-weather-app-aws-portfolio"
subdomain = "weather.portfolio"
project_owner = "your_name"
environment = "portfolio"
```

### 5. Configure OpenWeatherMap API

1. Sign up at [OpenWeatherMap](https://openweathermap.org/api)
2. Get your free API key
3. Edit `frontend/script.js`:

```javascript
const API_KEY = 'your_openweathermap_api_key_here';
```

### 6. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

### 7. Deploy Frontend Applications

```bash
# Deploy to AWS S3
aws s3 sync ../frontend/ s3://$(terraform output -raw aws_s3_bucket)/ --delete

# Deploy to Azure Blob Storage
az storage blob upload-batch \
    --account-name $(terraform output -raw azure_storage_account) \
    --destination '$web' \
    --source ../frontend/
```

### 8. Verify Deployment

```bash
# Test primary endpoint (AWS)
curl -I https://weather.portfolio.omesh.site

# Test secondary endpoint (Azure)
curl -I https://weather.portfolio-backup.omesh.site

# Check DNS resolution
dig +short weather.portfolio.omesh.site
```

## Alternative: Automated Deployment Script

For automated deployment, use the provided script:

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh
```

The script will:
1. Initialize Terraform
2. Apply infrastructure changes
3. Deploy frontend to both AWS and Azure
4. Verify deployments
5. Display access URLs

## Testing Disaster Recovery

### Automated Failover Testing

```bash
# Run the failover test script
chmod +x scripts/test-failover.sh
./scripts/test-failover.sh weather.portfolio.omesh.site
```

### Manual Failover Testing

1. **Test Primary Endpoint (AWS)**
   ```bash
   curl -I https://weather.portfolio.omesh.site
   # Should return 200 OK from CloudFront
   ```

2. **Simulate AWS Failure**
   - Go to AWS CloudFront Console
   - Find your distribution
   - Disable the distribution temporarily
   - Wait 3-5 minutes for health check to fail

3. **Verify Failover to Azure**
   ```bash
   # Monitor DNS changes
   watch -n 5 'dig +short weather.portfolio.omesh.site'
   
   # Test secondary endpoint
   curl -I https://weather.portfolio-backup.omesh.site
   ```

4. **Test Recovery**
   - Re-enable AWS CloudFront distribution
   - Wait for health check to recover
   - Verify traffic returns to primary

### Health Check Monitoring

```bash
# Check Route 53 health check status
aws route53 get-health-check --health-check-id YOUR_HEALTH_CHECK_ID

# Monitor health check metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/Route53 \
    --metric-name HealthCheckStatus \
    --dimensions Name=HealthCheckId,Value=YOUR_HEALTH_CHECK_ID
```

## Troubleshooting

### Common Issues & Solutions

#### 1. Terraform Authentication Issues

```bash
# AWS credentials
aws sts get-caller-identity

# Azure credentials
az account show

# Cloudflare API token test
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_API_TOKEN"
```

#### 2. Certificate Validation Failures

```bash
# Check ACM certificate status
aws acm list-certificates --region us-east-1

# Verify DNS validation records
dig TXT _acme-challenge.weather.portfolio.omesh.site
```

#### 3. S3 Deployment Issues

```bash
# Check S3 bucket policy
aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME

# Test S3 sync manually
aws s3 sync frontend/ s3://YOUR_BUCKET_NAME/ --delete --dryrun
```

#### 4. Azure Storage Issues

```bash
# Check storage account
az storage account show --name YOUR_STORAGE_ACCOUNT --resource-group weather-tracker-rg

# Enable static website
az storage blob service-properties update --account-name YOUR_STORAGE_ACCOUNT --static-website
```

#### 5. Health Check Failures

```bash
# Test endpoint manually
curl -v https://weather.portfolio.omesh.site

# Check CloudFront distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

### Diagnostic Commands

```bash
# View Terraform state
terraform show

# Check specific outputs
terraform output aws_cloudfront_domain
terraform output azure_cdn_endpoint
terraform output domain_name

# Validate Terraform configuration
terraform validate

# Plan without applying
terraform plan
```

### Emergency Procedures

```bash
# Force failover to Azure (manual)
# Update Cloudflare DNS record to point to Azure CDN

# Rollback deployment
terraform destroy -target=module.aws_infrastructure

# Complete infrastructure teardown
terraform destroy
```

## Cost Optimization

### AWS Cost Management

```bash
# Set up billing alerts
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget file://budget.json

# Monitor CloudFront usage
aws cloudwatch get-metric-statistics --namespace AWS/CloudFront --metric-name Requests
```

### Azure Cost Management

```bash
# Check current costs
az consumption usage list --top 10

# Set up budget alerts
az consumption budget create --budget-name weather-app-budget --amount 10
```

### Cost Optimization Tips

- Use AWS Free Tier: S3 (5GB), CloudFront (1TB), ACM (free)
- Azure Free Tier: Storage (5GB), CDN (15GB)
- Cloudflare Free Tier: DNS, SSL, CDN (100GB)
- Monitor usage with CloudWatch and Azure Monitor
- Set up billing alerts for both clouds

## Security Best Practices

### AWS Security

```bash
# Enable CloudTrail
aws cloudtrail create-trail --name weather-app-trail --s3-bucket-name your-cloudtrail-bucket

# Check S3 bucket security
aws s3api get-bucket-acl --bucket YOUR_BUCKET_NAME
```

### Azure Security

```bash
# Enable activity logging
az monitor activity-log list --resource-group weather-tracker-rg

# Check storage account security
az storage account show --name YOUR_STORAGE_ACCOUNT --query "encryption"
```

### Security Checklist

- ☑️ HTTPS-only access enforced
- ☑️ Origin Access Control configured
- ☑️ IAM least privilege policies
- ☑️ SSL/TLS certificates valid
- ☑️ CloudTrail and Activity Log enabled
- ☑️ Regular security audits scheduled
- ☑️ API keys rotated regularly

## Monitoring & Maintenance

### Health Monitoring

```bash
# Check health check status
aws route53 get-health-check --health-check-id YOUR_HEALTH_CHECK_ID

# Monitor application performance
aws cloudwatch get-metric-statistics --namespace AWS/CloudFront --metric-name OriginLatency
```

### Regular Maintenance Tasks

1. **Weekly:**
   - Review health check logs
   - Monitor cost usage
   - Check SSL certificate expiry

2. **Monthly:**
   - Update dependencies
   - Review security logs
   - Test disaster recovery procedures

3. **Quarterly:**
   - Security audit
   - Performance optimization review
   - Cost optimization analysis