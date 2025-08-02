# 2048 Game CI/CD Pipeline - Complete Deployment Guide

## 📋 Prerequisites Checklist

### Required Tools
- [ ] **AWS CLI** - Version 2.x configured with credentials
- [ ] **Terraform** - Version 1.0+ installed
- [ ] **Docker Desktop** - Running and accessible
- [ ] **Node.js** - Version 18+ for frontend development
- [ ] **Python** - Version 3.11+ for backend development
- [ ] **Git** - For repository management

### AWS Account Setup
- [ ] **AWS Account** - Active account with billing enabled
- [ ] **IAM User** - With programmatic access and required permissions
- [ ] **GitHub Token** - Personal access token for CodePipeline
- [ ] **Region Selection** - Choose your preferred AWS region (default: ap-south-1)

### Required AWS Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*",
        "codepipeline:*",
        "codebuild:*",
        "s3:*",
        "iam:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🚀 Step-by-Step Deployment

### Step 1: Repository Setup
```bash
# Clone the repository
git clone https://github.com/your-username/aws-portfolio.git
cd aws-portfolio/13-2048-game-codepipeline

# Verify project structure
ls -la
# Should see: app.py, buildspec.yml, docker/, frontend/, infrastructure/
```

### Step 2: Configure Terraform Variables
```bash
cd infrastructure

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**terraform.tfvars content:**
```hcl
aws_region = "ap-south-1"
project_name = "project-13-2048-game-codepipeline"
github_owner = "your-github-username"
github_repo = "aws-portfolio"
github_token = "ghp_your_github_personal_access_token"
```

### Step 3: Test Local Development
```bash
# Test backend locally
cd ../
python -m pip install -r requirements.txt
python app.py
# Should start on http://localhost:8080

# In another terminal, test frontend
cd frontend/
npm install
npm run dev
# Should start on http://localhost:5173
```

### Step 4: Test Docker Build
```bash
# Build Docker image
docker build -f docker/Dockerfile -t 2048-game-local .

# Test container
docker run -p 8081:8080 2048-game-local
# Should be accessible on http://localhost:8081

# Test API endpoint
curl http://localhost:8081/
# Should return: {"message":"2048 Game API","status":"healthy"}
```

### Step 5: Deploy Infrastructure
```bash
cd infrastructure/

# Initialize Terraform
terraform init
# ✅ Should download AWS provider

# Plan deployment
terraform plan
# ✅ Should show ~31 resources to create

# Apply infrastructure
terraform apply
# Type 'yes' when prompted
# ⏱️ Takes 5-10 minutes to complete
```

**Expected Terraform Outputs:**
```
api_url = "http://project-13-2048-game-codepp-alb-xxxxxxxxx.ap-south-1.elb.amazonaws.com"
ecr_repository_url = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/project-13-2048-game-codepp-repo-xxxxxxxx"
s3_bucket_name = "project-13-2048-game-codepp-frontend"
codepipeline_name = "project-13-2048-game-codepp-pipeline"
```

### Step 6: Initial Container Deployment
```bash
# Get ECR repository URL from terraform output
ECR_REPO=$(terraform output -raw ecr_repository_url)
echo $ECR_REPO

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_REPO

# Tag and push initial image
docker tag 2048-game-local:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# Update ECS service
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment
```

### Step 7: Wait for Service Health
```bash
# Check ECS service status
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].{runningCount:runningCount,desiredCount:desiredCount,status:status}"

# Check load balancer targets
ALB_TG_ARN=$(aws elbv2 describe-target-groups --names project-13-2048-game-codepp-tg --query "TargetGroups[0].TargetGroupArn" --output text)
aws elbv2 describe-target-health --target-group-arn $ALB_TG_ARN

# Wait for healthy status (2-5 minutes)
# Status should show: "State": "healthy"
```

### Step 8: Test API Endpoint
```bash
# Get API URL
API_URL=$(terraform output -raw api_url)
echo "API URL: $API_URL"

# Test health endpoint
curl $API_URL
# Should return: {"message":"2048 Game API","status":"healthy"}

# Test game creation
curl -X POST $API_URL -H "Content-Type: application/json" -d '{"action":"new"}'
# Should return game state with board and score
```

### Step 9: Deploy Frontend
```bash
cd ../frontend/

# Update environment with API URL
echo "VITE_API_URL=$API_URL" > .env

# Build frontend
npm run build

# Deploy to S3
S3_BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 sync dist/ s3://$S3_BUCKET --delete

# Get frontend URL
echo "Frontend URL: http://$S3_BUCKET.s3-website.ap-south-1.amazonaws.com"
```

### Step 10: Test Complete Application
```bash
# Open frontend URL in browser
# Should see 2048 game interface

# Test game functionality:
# 1. Click "New Game" button
# 2. Use arrow keys to move tiles
# 3. Verify score updates
# 4. Check mobile controls work
```

---

## 🔄 CI/CD Pipeline Setup

### Step 11: Trigger Pipeline
```bash
# Make a small change to trigger pipeline
cd ../
echo "# Updated $(date)" >> README.md

# Commit and push
git add .
git commit -m "Trigger CI/CD pipeline"
git push origin main
```

### Step 12: Monitor Pipeline
```bash
# Check pipeline status
aws codepipeline get-pipeline-state --name project-13-2048-game-codepp-pipeline

# Monitor build logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild/project-13-2048-game-codepp-build"

# Get latest build ID
BUILD_ID=$(aws codebuild list-builds-for-project --project-name project-13-2048-game-codepp-build --sort-order DESCENDING --max-items 1 --query "ids[0]" --output text)

# View build logs
aws logs get-log-events --log-group-name "/aws/codebuild/project-13-2048-game-codepp-build" --log-stream-name $BUILD_ID
```

---

## ⏱️ Expected Timelines

### Initial Deployment
- **Terraform Apply**: 8-12 minutes
- **Container Build**: 2-3 minutes
- **ECS Service Start**: 3-5 minutes
- **Load Balancer Health**: 2-3 minutes
- **Frontend Deploy**: 1-2 minutes
- **Total Time**: 15-25 minutes

### CI/CD Pipeline
- **Source Stage**: 30 seconds
- **Build Stage**: 3-5 minutes
- **Deploy Stage**: 2-3 minutes
- **Health Check**: 1-2 minutes
- **Total Pipeline**: 6-10 minutes

---

## 🔍 Troubleshooting Common Issues

### Issue 1: Terraform Apply Fails
**Symptoms:**
```
Error: creating S3 Bucket Policy: AccessDenied
```

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam get-user-policy --user-name your-username --policy-name your-policy

# Fix dependency order
terraform apply -target=aws_s3_bucket_public_access_block.frontend
terraform apply
```

### Issue 2: Docker Build Fails in CodeBuild
**Symptoms:**
```
ERROR: resolve : lstat docker: no such file or directory
```

**Solution:**
```bash
# Check buildspec.yml paths
cd 13-2048-game-codepipeline
ls -la docker/
# Should see Dockerfile

# Verify buildspec.yml navigation
grep -n "cd 13-2048-game-codepipeline" buildspec.yml
```

### Issue 3: ECS Service Won't Start
**Symptoms:**
```
Service has reached a steady state with 0 running tasks
```

**Solution:**
```bash
# Check task definition
aws ecs describe-task-definition --task-definition project-13-2048-game-codepp-task

# Check service events
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].events"

# Check CloudWatch logs
aws logs describe-log-streams --log-group-name "/ecs/project-13-2048-game-codepp"
```

### Issue 4: Load Balancer Health Check Fails
**Symptoms:**
```
Target health: unhealthy
```

**Solution:**
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# Verify ALB can reach ECS
# ALB security group should allow port 80 from 0.0.0.0/0
# ECS security group should allow port 8080 from ALB security group

# Test container health
docker run -p 8080:8080 $ECR_REPO:latest
curl http://localhost:8080/
```

### Issue 5: Frontend Can't Connect to API
**Symptoms:**
```
CORS error or network timeout
```

**Solution:**
```bash
# Check API URL in frontend
cat frontend/.env
# Should match ALB DNS name

# Test API directly
curl $API_URL
curl -X POST $API_URL -H "Content-Type: application/json" -d '{"action":"new"}'

# Rebuild and redeploy frontend
cd frontend/
npm run build
aws s3 sync dist/ s3://$S3_BUCKET --delete
```

### Issue 6: CodePipeline Permission Errors
**Symptoms:**
```
User is not authorized to perform: elasticloadbalancing:DescribeLoadBalancers
```

**Solution:**
```bash
# Update CodeBuild IAM role
terraform apply -target=aws_iam_role_policy.codebuild_policy

# Or manually add permissions
aws iam put-role-policy --role-name project-13-2048-game-codepp-codebuild-role --policy-name ELBAccess --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:DescribeLoadBalancers"],
      "Resource": "*"
    }
  ]
}'
```

---

## 🔧 Configuration Customization

### Change AWS Region
```bash
# Update terraform.tfvars
aws_region = "us-east-1"

# Update buildspec.yml
# Change hardcoded ALB DNS name to match new region

# Redeploy
terraform plan
terraform apply
```

### Modify Container Resources
```bash
# Edit infrastructure/main.tf
resource "aws_ecs_task_definition" "app" {
  cpu    = 512  # Change from 256
  memory = 1024 # Change from 512
}

# Apply changes
terraform apply
```

### Update GitHub Repository
```bash
# Edit terraform.tfvars
github_owner = "new-username"
github_repo = "new-repository"

# Update pipeline
terraform apply -target=aws_codepipeline.pipeline
```

---

## 📊 Monitoring and Maintenance

### Health Check Commands
```bash
# Check all services
./scripts/health-check.sh

# Individual service checks
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE
aws elbv2 describe-target-health --target-group-arn $ALB_TG_ARN
aws s3 ls s3://$S3_BUCKET
aws codepipeline get-pipeline-state --name project-13-2048-game-codepp-pipeline
```

### Log Monitoring
```bash
# ECS application logs
aws logs tail "/ecs/project-13-2048-game-codepp" --follow

# CodeBuild logs
aws logs tail "/aws/codebuild/project-13-2048-game-codepp-build" --follow

# Load balancer access logs (if enabled)
aws s3 ls s3://your-alb-logs-bucket/
```

### Cost Monitoring
```bash
# Check current costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

# Set up billing alerts
aws cloudwatch put-metric-alarm --alarm-name "HighBilling" --alarm-description "Alert when billing exceeds $50" --metric-name EstimatedCharges --namespace AWS/Billing --statistic Maximum --period 86400 --threshold 50 --comparison-operator GreaterThanThreshold
```

---

## 🧹 Cleanup Instructions

### Complete Cleanup
```bash
# Destroy all infrastructure
cd infrastructure/
terraform destroy
# Type 'yes' when prompted

# Clean up local Docker images
docker rmi 2048-game-local
docker rmi $ECR_REPO:latest

# Remove local files
cd ../
rm -rf node_modules/
rm -rf frontend/node_modules/
rm -rf frontend/dist/
```

### Partial Cleanup (Keep Infrastructure)
```bash
# Stop ECS service
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --desired-count 0

# Delete S3 objects
aws s3 rm s3://$S3_BUCKET --recursive

# Disable CodePipeline
aws codepipeline stop-pipeline-execution --pipeline-name project-13-2048-game-codepp-pipeline --pipeline-execution-id $(aws codepipeline get-pipeline-state --name project-13-2048-game-codepp-pipeline --query "stageStates[0].latestExecution.pipelineExecutionId" --output text)
```

---

## 📞 Support and Resources

### Getting Help
- **AWS Documentation**: [ECS](https://docs.aws.amazon.com/ecs/), [CodePipeline](https://docs.aws.amazon.com/codepipeline/)
- **Terraform Registry**: [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **GitHub Issues**: Create issue in repository for project-specific problems

### Useful Commands Reference
```bash
# Quick status check
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].{status:status,running:runningCount,desired:desiredCount}"

# Force new deployment
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment

# Check pipeline status
aws codepipeline get-pipeline-state --name project-13-2048-game-codepp-pipeline --query "stageStates[*].{stage:stageName,status:latestExecution.status}"

# View recent logs
aws logs tail "/ecs/project-13-2048-game-codepp" --since 1h
```

---

**🎯 Success Criteria:**
- ✅ API responds at ALB endpoint
- ✅ Frontend loads from S3 website
- ✅ Game functions correctly (new game, moves, score)
- ✅ Pipeline triggers on git push
- ✅ Automated deployment completes successfully

**⚠️ Remember:** This deployment creates AWS resources that incur costs. Monitor your usage and clean up when not needed.