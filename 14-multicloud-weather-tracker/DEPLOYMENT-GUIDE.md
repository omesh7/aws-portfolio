# 🚀 Multi-Cloud Weather Tracker Deployment Guide

## Prerequisites

### Required Tools
- **Terraform** (>= 1.0)
- **AWS CLI** (configured with credentials)
- **Azure CLI** (for multi-cloud setup)
- **Cloudflare account** with domain access

### API Keys
- **OpenWeatherMap API key** (free tier available)
- **Cloudflare API token** with Zone:Edit permissions

## 📋 Step-by-Step Deployment

### 1. Configuration Setup

```bash
# Clone and navigate
cd 14-multicloud-weather-tracker

# Copy configuration template
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
openweather_api_key = "your-openweather-api-key"
cloudflare_api_token = "your-cloudflare-token"
domain_name = "your-domain.com"
subdomain = "weather"
project_name = "weather-app"
```

### 2. Deploy Infrastructure

**Option A: Windows**
```cmd
# From any directory
scripts\windows\deploy.bat
```

**Option B: Linux**
```bash
# Make executable (first time only)
chmod +x scripts/linux/*.sh

# Deploy from any directory
scripts/linux/deploy.sh
```

### 3. Verify Deployment

```cmd
# Check status
scripts\windows\status.bat    # Windows
scripts/linux/status.sh       # Linux
```

Expected output:
```
Multi-Cloud Weather Tracker Status
===================================
Infrastructure Status:
Lambda: Deployed
Weather App: https://weather.portfolio.your-domain.com

Testing endpoints...
✅ API: Working
```

### 4. Test Failover

```cmd
scripts\windows\test-failover.bat    # Windows
scripts/linux/test-failover.sh       # Linux
```

## 🌐 Multi-Cloud Configuration (Optional)

### Enable Azure Backup

1. **Uncomment Azure resources** in `terraform/main.tf`:
```hcl
# Uncomment for multi-cloud setup
module "azure_infrastructure" {
  source = "./modules/azure"
  # ... configuration
}
```

2. **Uncomment Azure outputs** in `terraform/outputs.tf`:
```hcl
output "azure_storage_account" {
  description = "Azure storage account name"
  value       = module.azure_infrastructure.storage_account_name
}
```

3. **Update deployment scripts** to include Azure:
```bash
# In deploy scripts, uncomment:
# az storage blob upload-batch --account-name $AZURE_STORAGE ...
```

4. **Configure Azure CLI**:
```bash
az login
az account set --subscription "your-subscription-id"
```

### Full Multi-Cloud Benefits
- ✅ **Automatic failover** from AWS to Azure
- ✅ **Health monitoring** every 30 seconds
- ✅ **Zero downtime** during outages
- ✅ **Geographic redundancy**

## 🔧 Troubleshooting

### Common Issues

**1. CORS Errors**
```bash
# Check Lambda CORS configuration
terraform output aws_lambda_function_url_weather_tracker_url
```

**2. API Key Issues**
```bash
# Verify OpenWeather API key
curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_KEY"
```

**3. DNS Propagation**
```bash
# Check DNS resolution
nslookup weather.your-domain.com
```

**4. Terraform State Lock**
```bash
# Force unlock if needed
terraform force-unlock LOCK_ID
```

### Script Debugging

**Windows:**
```cmd
# Enable verbose output
set TERRAFORM_LOG=DEBUG
scripts\windows\deploy.bat
```

**Linux:**
```bash
# Enable debug mode
set -x
scripts/linux/deploy.sh
```

## 🧹 Cleanup

### Destroy Resources

```cmd
scripts\windows\destroy.bat    # Windows
scripts/linux/destroy.sh       # Linux
```

### Manual Cleanup (if needed)
```bash
# Remove Terraform state
rm terraform/terraform.tfstate*

# Clean temporary files
rm -rf temp-frontend/
rm lambda_14.zip
```

## 📊 Monitoring & Maintenance

### Health Checks
- **Cloudflare**: Monitors primary endpoint every 30s
- **Status scripts**: Manual health verification
- **Failover tests**: Validate disaster recovery

### Updates
```bash
# Update infrastructure
scripts/windows/deploy.bat

# Check changes
terraform plan
```

### Logs
- **AWS CloudWatch**: Lambda function logs
- **Cloudflare Analytics**: Traffic and failover events
- **Local logs**: Script execution output

## 🎯 Production Considerations

### Security
- ✅ HTTPS enforced via CloudFront/CDN
- ✅ API keys stored in Terraform variables
- ✅ CORS properly configured
- ✅ No hardcoded credentials

### Performance
- ✅ CDN caching for static assets
- ✅ Lambda cold start optimization
- ✅ Gzip compression enabled
- ✅ Health check intervals optimized

### Reliability
- ✅ Multi-cloud redundancy ready
- ✅ Automated failover configured
- ✅ Health monitoring active
- ✅ Error handling implemented

## 📞 Support

For issues:
1. Check the troubleshooting section
2. Run status scripts for diagnostics
3. Review Terraform and script logs
4. Verify all prerequisites are met

The deployment is designed to be robust and self-healing with proper monitoring and failover capabilities.