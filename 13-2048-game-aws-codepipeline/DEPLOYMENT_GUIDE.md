# 🚀 2048 Game CI/CD Pipeline - Deployment Guide

Complete deployment guide for the 2048 Game with AWS CodePipeline, ECS Fargate, and Grafana monitoring.

## 📋 Prerequisites

### Required Tools
```bash
# Essential tools
AWS CLI >= 2.0
Terraform >= 1.0
Docker Desktop
Git
GitHub CLI (gh)

# Verify installations
aws --version
terraform version
docker --version
gh --version
```

### Required Access & Tokens

#### 1. AWS Credentials
```bash
# Configure AWS CLI with programmatic access
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region: ap-south-1
# - Default output format: json

# Verify access
aws sts get-caller-identity
```

**Required AWS Permissions:**
- EC2 (VPC, Security Groups, Load Balancer)
- ECS (Cluster, Service, Task Definition)
- ECR (Repository management)
- S3 (Bucket creation and management)
- IAM (Role and policy creation)
- CodePipeline & CodeBuild
- CloudWatch (Logs and monitoring)

#### 2. GitHub Personal Access Token

**Required Scopes:**
- ✅ `repo` (Full control of private repositories)
- ✅ `workflow` (Update GitHub Action workflows)
- ✅ `actions:read` (Read access to actions and workflows)

**Create Token via GitHub CLI:**
```bash
# Login to GitHub
gh auth login

# Create token with required scopes
gh auth refresh -h github.com -s repo,workflow,actions:read

# Get token for environment variables
gh auth token
```

**Or create manually:**
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select required scopes above
4. Copy token immediately

#### 3. Grafana Cloud Account (Optional - for monitoring)

**Setup Grafana Cloud:**
1. Sign up at [grafana.com](https://grafana.com)
2. Create new stack
3. Get API key from stack settings
4. Note your Grafana URL and organization ID

## 🏗️ Project Architecture

```
GitHub Repository
    ↓ (Webhook/Polling)
AWS CodePipeline
    ├── Source Stage (GitHub)
    ├── Build Backend (CodeBuild → ECR)
    └── Build Frontend (CodeBuild → S3)
    ↓
ECS Fargate Cluster
    ├── Application Load Balancer
    ├── Backend Service (Docker)
    └── Frontend (S3 + CloudFront)
    ↓
CloudWatch Monitoring
    └── Grafana Dashboard (Optional)
```

## 🚀 Deployment Steps

### Step 1: Clone and Setup Repository

```bash
# Clone the portfolio repository
git clone https://github.com/omesh7/aws-portfolio.git
cd aws-portfolio/13-2048-game-aws-codepipeline

# Verify project structure
ls -la
# Should see: infrastructure/, backend/, frontend/, buildspec/
```

### Step 2: Configure Environment Variables

```bash
# Copy example terraform variables
cd infrastructure/
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Required terraform.tfvars configuration:**
```hcl
# Project Configuration
project_name = "project-13-2048-game-codepp"
aws_region   = "ap-south-1"

# GitHub Configuration
github_owner = "your-github-username"
github_repo  = "aws-portfolio"
github_token = "your_github_personal_access_token_here"

# Optional: Custom domain
# domain_name = "your-domain.com"

# Optional: Grafana monitoring
# grafana_api_key = "your_grafana_api_key"
# grafana_url     = "https://your-org.grafana.net"
```

### Step 3: Initialize and Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure (takes 10-15 minutes)
terraform apply
# Type 'yes' when prompted

# Save important outputs
terraform output
```

**Expected Outputs:**
```
alb_dns_name = "project-13-alb-xxxxx.ap-south-1.elb.amazonaws.com"
ecr_repository_url = "123456789.dkr.ecr.ap-south-1.amazonaws.com/project-13-2048-game"
frontend_url = "http://project-13-2048-game-frontend.s3-website.ap-south-1.amazonaws.com"
pipeline_name = "project-13-2048-game-pipeline-xxxxx"
```

### Step 4: Verify Deployment

#### Check AWS Resources
```bash
# Verify ECS cluster
aws ecs describe-clusters --clusters project-13-2048-game-cluster-*

# Check CodePipeline status
aws codepipeline get-pipeline-state --name project-13-2048-game-pipeline-*

# Verify S3 bucket
aws s3 ls | grep project-13
```

#### Test Application
```bash
# Get frontend URL
FRONTEND_URL=$(terraform output -raw frontend_url)
echo "Frontend: $FRONTEND_URL"

# Get backend URL  
BACKEND_URL=$(terraform output -raw alb_dns_name)
echo "Backend: http://$BACKEND_URL"

# Test endpoints
curl -I $FRONTEND_URL
curl -I http://$BACKEND_URL/health
```

### Step 5: Trigger First Pipeline Run

The pipeline will automatically trigger on the first push after deployment. To manually trigger:

```bash
# Make a small change to trigger pipeline
echo "# Pipeline test" >> README.md
git add README.md
git commit -m "Trigger pipeline"
git push origin main

# Monitor pipeline progress
aws codepipeline get-pipeline-execution --pipeline-name project-13-2048-game-pipeline-*
```

## 📊 Monitoring Setup (Optional)

### Grafana Dashboard Configuration

If you provided Grafana credentials, the dashboard will be automatically configured. Otherwise:

1. **Import Dashboard:**
   - Use dashboard ID: `15141` (AWS ECS monitoring)
   - Or import from `monitoring/grafana-dashboard.json`

2. **Configure Data Source:**
   ```json
   {
     "type": "cloudwatch",
     "name": "AWS CloudWatch",
     "region": "ap-south-1",
     "defaultRegion": "ap-south-1"
   }
   ```

3. **Key Metrics to Monitor:**
   - ECS Service CPU/Memory utilization
   - ALB request count and latency
   - CodePipeline execution status
   - S3 bucket requests

## 🔧 Configuration Details

### CodePipeline Stages

1. **Source Stage:**
   - Polls GitHub repository every minute
   - Triggers on main branch changes
   - Uses GitHub OAuth token for access

2. **Build Backend Stage:**
   - Builds Docker image from `backend/`
   - Pushes to ECR repository
   - Updates ECS service with new image

3. **Build Frontend Stage:**
   - Builds React application from `frontend/`
   - Deploys static files to S3
   - Configures S3 website hosting

### Environment Variables in CodeBuild

The pipeline automatically configures these environment variables:

```bash
AWS_DEFAULT_REGION=ap-south-1
ECR_REPOSITORY_URI=<ecr-repo-url>
ECS_CLUSTER_NAME=<cluster-name>
ECS_SERVICE_NAME=<service-name>
S3_BUCKET=<frontend-bucket>
TASK_DEFINITION_FAMILY=<task-family>
ALB_DNS_NAME=<load-balancer-dns>
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. GitHub Token Issues
```bash
# Test token permissions
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Refresh token scopes
gh auth refresh -h github.com -s repo,workflow,actions:read
```

#### 2. CodePipeline Failures
```bash
# Check pipeline execution details
aws codepipeline get-pipeline-execution --pipeline-name <pipeline-name> --pipeline-execution-id <execution-id>

# View CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/project-13
```

#### 3. ECS Service Issues
```bash
# Check service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# View service events
aws ecs describe-services --cluster <cluster-name> --services <service-name> --query 'services[0].events'

# Check task logs
aws logs tail /ecs/project-13-2048-game --follow
```

#### 4. Frontend Not Loading
```bash
# Verify S3 bucket policy
aws s3api get-bucket-policy --bucket <frontend-bucket>

# Check website configuration
aws s3api get-bucket-website --bucket <frontend-bucket>

# Test direct S3 access
curl -I http://<frontend-bucket>.s3-website.ap-south-1.amazonaws.com
```

### Debug Commands

```bash
# View all project resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=project-13-2048-game

# Check ECR images
aws ecr describe-images --repository-name project-13-2048-game

# Monitor ECS tasks
aws ecs list-tasks --cluster <cluster-name> --service-name <service-name>
```

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Navigate to infrastructure directory
cd infrastructure/

# Destroy all resources
terraform destroy
# Type 'yes' when prompted

# Verify cleanup
aws ecs list-clusters
aws ecr describe-repositories
aws s3 ls | grep project-13
```

### Manual Cleanup (if needed)
```bash
# Force delete ECR repository
aws ecr delete-repository --repository-name project-13-2048-game --force

# Empty and delete S3 buckets
aws s3 rm s3://<bucket-name> --recursive
aws s3 rb s3://<bucket-name>

# Delete CloudWatch log groups
aws logs delete-log-group --log-group-name /ecs/project-13-2048-game
aws logs delete-log-group --log-group-name /aws/codebuild/project-13-*
```

## 📈 Performance & Scaling

### Auto Scaling Configuration
- **ECS Service:** 1-10 tasks based on CPU/memory
- **ALB:** Handles 1000+ concurrent connections
- **S3:** Unlimited static file serving
- **CodePipeline:** Concurrent builds supported

### Cost Optimization
- **ECS Fargate:** Pay per task runtime
- **S3:** Standard storage with lifecycle policies
- **ALB:** Pay per hour + data processed
- **CodePipeline:** First 1 pipeline free, $1/month additional

**Estimated Monthly Cost:** $15-30 for moderate usage

## 🔐 Security Best Practices

### Implemented Security Features
- ✅ IAM roles with least privilege access
- ✅ VPC with private subnets for ECS tasks
- ✅ Security groups restricting network access
- ✅ ECR image scanning enabled
- ✅ S3 bucket policies for public read-only access
- ✅ ALB with security groups
- ✅ CloudWatch logging for audit trails

### Additional Security Recommendations
- Enable AWS Config for compliance monitoring
- Set up AWS GuardDuty for threat detection
- Use AWS Secrets Manager for sensitive data
- Enable VPC Flow Logs for network monitoring
- Implement AWS WAF for web application protection

## 📞 Support & Resources

### Useful Links
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [ECS Fargate Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Integration](https://docs.github.com/en/actions)

### Project Structure
```
13-2048-game-aws-codepipeline/
├── infrastructure/          # Terraform IaC
│   ├── main.tf             # Main configuration
│   ├── codepipeline.tf     # CI/CD pipeline
│   ├── ecs.tf              # Container orchestration
│   └── variables.tf        # Input variables
├── backend/                # Flask API
│   ├── app.py              # Game logic
│   └── Dockerfile          # Container definition
├── frontend/               # React UI
│   ├── src/                # Source code
│   └── package.json        # Dependencies
├── buildspec/              # CodeBuild specifications
│   ├── backend-buildspec.yml
│   └── frontend-buildspec.yml
└── monitoring/             # Grafana dashboards
    └── grafana-dashboard.json
```

---

**🎮 Ready to deploy your 2048 Game with enterprise CI/CD pipeline!**

For issues or questions, check the troubleshooting section or create an issue in the GitHub repository.