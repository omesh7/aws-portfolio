# 🌤️ Multi-Cloud Weather Tracker - Deployment Scripts

**Cross-platform deployment automation that works from any directory location**

## ✨ Features

- **Universal Path Resolution** - Works from any terminal location
- **Comprehensive Error Handling** - Clear error messages and validation
- **Prerequisites Checking** - Validates tools and credentials before deployment
- **Resource Cleanup** - Automatic S3 bucket emptying before destruction
- **Health Monitoring** - Endpoint testing and status reporting
- **User-Friendly Output** - Color-coded status messages and progress indicators
- **Cross-Platform** - Identical functionality on Windows and Linux

---

## 🐧 Linux Scripts (`linux/`)

### Prerequisites
```bash
# Make scripts executable (one-time setup)
chmod +x scripts/linux/*.sh

# Required tools
- Terraform >= 1.0
- AWS CLI (configured)
- curl (for endpoint testing)
```

### 🚀 Deploy Infrastructure
```bash
# Works from any directory
./scripts/linux/deploy.sh

# Or from project root
scripts/linux/deploy.sh

# Or from anywhere in your system
/path/to/project/scripts/linux/deploy.sh
```

**What it does:**
- ✅ Validates prerequisites (Terraform, AWS CLI, credentials)
- ✅ Checks for terraform.tfvars configuration
- ✅ Initializes and plans Terraform deployment
- ✅ Deploys AWS infrastructure (Lambda, S3, CloudFront)
- ✅ Configures and uploads frontend with API endpoints
- ✅ Provides deployment URL and status

### 📊 Check Status
```bash
./scripts/linux/status.sh
```

**What it does:**
- 📋 Shows all deployed resources (S3, CloudFront, Lambda)
- 🧪 Tests API and frontend endpoints
- ⚡ Reports response times and HTTP status codes
- 🔍 Validates deployment health

### 🔄 Test Failover
```bash
./scripts/linux/test-failover.sh
```

**What it does:**
- 🧪 Tests primary AWS infrastructure
- 📊 Reports failover readiness status
- 📖 Provides manual failover testing guide
- 🌐 Shows Google Cloud setup instructions

### 🗑️ Destroy Infrastructure
```bash
./scripts/linux/destroy.sh
```

**What it does:**
- ⚠️ Requires confirmation before destruction
- 🧹 Empties S3 buckets automatically
- 🗑️ Destroys all Terraform-managed resources
- ✅ Confirms successful cleanup

---

## 🪟 Windows Scripts (`windows/`)

### Prerequisites
```cmd
REM Required tools
- Terraform >= 1.0
- AWS CLI (configured)
- curl (optional, for endpoint testing)
```

### 🚀 Deploy Infrastructure
```cmd
REM Works from any directory
scripts\windows\deploy.bat

REM Or double-click the file in Explorer
```

### 📊 Check Status
```cmd
scripts\windows\status.bat
```

### 🔄 Test Failover
```cmd
scripts\windows\test-failover.bat
```

### 🗑️ Destroy Infrastructure
```cmd
scripts\windows\destroy.bat
```

---

## 🔧 Configuration Setup

### 1. Copy Configuration Template
```bash
# Navigate to infrastructure directory
cd infrastructure/

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration
```hcl
# terraform.tfvars
aws_region = "ap-south-1"
gcp_region = "us-central1"  # For future multi-cloud setup
gcp_project_id = "your-gcp-project-id"

# Cloudflare Configuration
cloudflare_api_token = "your_cloudflare_api_token"
cloudflare_zone_id = "your_cloudflare_zone_id"

# Project Configuration
project_name = "14-weather-app-aws-portfolio"
subdomain = "weather.portfolio"
project_owner = "your_name"
environment = "portfolio"

# API Keys
openweather_api_key = "your_openweather_api_key"
```

### 3. AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

---

## 🚀 Quick Start Guide

### Complete Deployment (Linux)
```bash
# 1. Clone and navigate
git clone <repository>
cd 14-multicloud-weather-tracker

# 2. Configure
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Make scripts executable
chmod +x scripts/linux/*.sh

# 4. Deploy
scripts/linux/deploy.sh

# 5. Check status
scripts/linux/status.sh

# 6. Test failover capabilities
scripts/linux/test-failover.sh
```

### Complete Deployment (Windows)
```cmd
REM 1. Clone and navigate
git clone <repository>
cd 14-multicloud-weather-tracker

REM 2. Configure
copy infrastructure\terraform.tfvars.example infrastructure\terraform.tfvars
REM Edit terraform.tfvars with your values

REM 3. Deploy
scripts\windows\deploy.bat

REM 4. Check status
scripts\windows\status.bat

REM 5. Test failover
scripts\windows\test-failover.bat
```

---

## 🔍 Troubleshooting

### Common Issues

**Script not found:**
```bash
# Ensure you're using the correct path separators
# Linux: scripts/linux/deploy.sh
# Windows: scripts\windows\deploy.bat
```

**Permission denied (Linux):**
```bash
chmod +x scripts/linux/*.sh
```

**Terraform not found:**
```bash
# Install Terraform
# Linux: sudo apt install terraform
# Windows: choco install terraform
# Or download from: https://terraform.io/downloads
```

**AWS credentials not configured:**
```bash
aws configure
# Enter your AWS Access Key ID, Secret, Region, and Output format
```

**terraform.tfvars missing:**
```bash
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
# Edit the file with your actual values
```

### Debug Mode

**Enable Terraform debugging:**
```bash
# Linux
export TF_LOG=DEBUG

# Windows
set TF_LOG=DEBUG
```

**Test AWS connectivity:**
```bash
aws sts get-caller-identity
aws s3 ls
```

---

## 🌐 Multi-Cloud Setup (Optional)

### Enable Google Cloud Secondary

1. **Uncomment GCP resources in `infrastructure/main.tf`:**
```hcl
module "gcp_infrastructure" {
  source = "./modules/gcp"
  # ... configuration
}
```

2. **Configure GCP credentials:**
```bash
# Install Google Cloud CLI
# Configure authentication
gcloud auth application-default login
```

3. **Update terraform.tfvars:**
```hcl
gcp_project_id = "your-actual-gcp-project-id"
gcp_region = "us-central1"
```

4. **Deploy with multi-cloud:**
```bash
scripts/linux/deploy.sh
```

---

## 📊 Script Output Examples

### Successful Deployment
```
===========================================
🌤️  Multi-Cloud Weather Tracker Deployment
===========================================

📁 Project root: /path/to/project

🔍 Checking prerequisites...
✅ [OK] Terraform found
✅ [OK] AWS CLI found
✅ [OK] AWS credentials configured

🔧 [1/4] Initializing Terraform...
📋 [2/4] Planning deployment...
🚀 [3/4] Deploying infrastructure...
📦 [4/4] Deploying frontend...

===========================================
✅ Deployment completed successfully!
===========================================

🔗 Application URL: https://weather.portfolio.omesh.site
```

### Status Check
```
===========================================
📊 Multi-Cloud Weather Tracker - STATUS
===========================================

Resources:
  🪣 S3 Bucket: weather-app-bucket-12345
  ☁️  CloudFront: d1234567890.cloudfront.net
  λ Lambda API: https://abc123.lambda-url.region.on.aws/
  🌐 Weather App: https://weather.portfolio.omesh.site

ENDPOINT TESTING
===========================================

🧪 Testing Lambda API...
  ✓ Lambda API: Working (HTTP 200)
🌐 Testing Weather App...
  ✓ Weather App: Working (HTTP 200)

===========================================
STATUS CHECK COMPLETE
===========================================
```

---

**All scripts are designed to work reliably from any directory location and provide comprehensive feedback throughout the deployment process.**