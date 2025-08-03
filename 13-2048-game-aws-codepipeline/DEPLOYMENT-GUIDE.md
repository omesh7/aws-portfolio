# 2048 Game CI/CD Pipeline - Deployment Guide

Complete step-by-step guide to deploy the 2048 Game with automated CI/CD pipeline on AWS.

## 📋 Prerequisites

### Required Tools
- **AWS CLI v2** - Configured with credentials
- **Terraform >= 1.0** - Infrastructure as Code
- **Docker Desktop** - Container building and testing
- **Node.js >= 18** - Frontend development
- **Python 3.11+** - Backend development
- **Git** - Version control

### AWS Account Requirements
- Active AWS account with billing enabled
- IAM user with programmatic access
- GitHub personal access token for CodePipeline
- Sufficient permissions for creating AWS resources

### Required AWS Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*", "ecr:*", "codepipeline:*", "codebuild:*",
        "s3:*", "iam:*", "ec2:*", "elasticloadbalancing:*",
        "logs:*", "application-autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 Step-by-Step Deployment

### Step 1: Repository Setup
```bash
# Clone the repository
git clone <your-repository-url>
cd 13-2048-game-aws-codepipeline

# Verify project structure
ls -la
# Should see: app.py, buildspec/, frontend/, infrastructure/, scripts/
```

### Step 2: Configure Infrastructure
```bash
cd infrastructure

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

**terraform.tfvars configuration:**
```hcl
aws_region = "ap-south-1"
project_name = "proj-13-2048-game-cp"
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

# Test frontend locally (new terminal)
cd frontend/
npm install
npm run dev
# Should start on http://localhost:5173
```

### Step 4: Test Docker Build
```bash
# Build and test container
docker build -f docker/Dockerfile -t 2048-game-local .
docker run -p 8081:8080 2048-game-local

# Test API endpoint
curl http://localhost:8081/
# Should return: {"message":"2048 Game API","status":"healthy"}
```

### Step 5: Deploy Infrastructure
```bash
cd infrastructure/

# Initialize Terraform
terraform init

# Plan deployment (review changes)
terraform plan

# Deploy infrastructure
terraform apply
# Type 'yes' when prompted
# Takes 8-12 minutes to complete
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
# Get outputs from Terraform
ECR_REPO=$(terraform output -raw ecr_repository_url)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)

# Login to ECR and push initial image
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_REPO
docker tag 2048-game-local:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# Update ECS service
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment
```

### Step 7: Wait for Service Health
```bash
# Monitor ECS service status
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE \
  --query "services[0].{status:status,running:runningCount,desired:desiredCount}"

# Check load balancer target health
ALB_TG_ARN=$(terraform output -raw target_group_arn)
aws elbv2 describe-target-health --target-group-arn $ALB_TG_ARN

# Wait for "healthy" status (2-5 minutes)
```

### Step 8: Test API Endpoint
```bash
API_URL=$(terraform output -raw api_url)
echo "API URL: $API_URL"

# Test health endpoint
curl $API_URL
# Should return: {"message":"2048 Game API","status":"healthy"}

# Test game creation
curl -X POST $API_URL -H "Content-Type: application/json" -d '{"action":"new"}'
# Should return game state with board and score
```

### Step 9: Trigger CI/CD Pipeline
```bash
cd ../

# Trigger pipeline to build and deploy frontend
./scripts/run.sh trigger-build    # Linux/macOS
.\scripts\run.bat trigger-build   # Windows

# Monitor pipeline progress
./scripts/run.sh status
```

### Step 10: Verify Complete Application
```bash
# Get frontend URL
S3_BUCKET=$(terraform output -raw s3_bucket_name)
FRONTEND_URL="http://$S3_BUCKET.s3-website.ap-south-1.amazonaws.com"
echo "Frontend URL: $FRONTEND_URL"

# Test frontend accessibility
curl -I $FRONTEND_URL
# Should return HTTP 200 OK
```

## 🔄 CI/CD Pipeline Details

### Pipeline Architecture
```
GitHub Push → CodePipeline → {
  ├── Backend Build (buildspec/backend-buildspec.yml)
  │   ├── Docker build
  │   ├── ECR push
  │   └── ECS deploy
  └── Frontend Build (buildspec/frontend-buildspec.yml)
      ├── npm install
      ├── Create .env with API_URL
      ├── npm run build
      └── S3 deploy
}
```

### Build Process
1. **Source Stage:** Downloads code from GitHub
2. **Backend Build:** Parallel build of Docker container
3. **Frontend Build:** Parallel build of React application
4. **Deployment:** Automatic deployment to ECS and S3

### Environment Variables
The frontend build automatically receives:
- `API_URL`: Load balancer DNS name
- `S3_BUCKET`: Target S3 bucket name
- `AWS_DEFAULT_REGION`: Deployment region

## ⏱️ Expected Timelines

### Initial Deployment
- **Terraform Apply:** 8-12 minutes
- **Container Build & Push:** 2-3 minutes
- **ECS Service Start:** 3-5 minutes
- **Load Balancer Health:** 2-3 minutes
- **Pipeline Trigger:** 1-2 minutes
- **Total Time:** 15-25 minutes

### CI/CD Pipeline Execution
- **Source Stage:** 30 seconds
- **Backend Build:** 3-5 minutes
- **Frontend Build:** 2-3 minutes (parallel)
- **Deployment:** 1-2 minutes
- **Total Pipeline:** 6-10 minutes

## 🔍 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails
**Symptoms:** Permission denied or resource conflicts
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam get-user-policy --user-name your-username --policy-name your-policy

# Check for resource naming conflicts
terraform plan -detailed-exitcode
```

#### 2. Docker Build Fails
**Symptoms:** Build errors or permission issues
```bash
# Check Docker daemon
docker info

# Test local build
docker build -f docker/Dockerfile -t test-image .

# Check buildspec syntax
cat buildspec/backend-buildspec.yml
```

#### 3. ECS Service Won't Start
**Symptoms:** Service stuck in pending or tasks failing
```bash
# Check service events
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE \
  --query "services[0].events"

# Check task logs
aws logs tail "/ecs/project-name" --follow

# Verify security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### 4. Frontend Build Fails
**Symptoms:** Pipeline fails at frontend build stage
```bash
# Check CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild"

# Get latest build logs
BUILD_PROJECT="project-name-frontend-build"
aws codebuild list-builds-for-project --project-name $BUILD_PROJECT \
  --sort-order DESCENDING --max-items 1
```

#### 5. Load Balancer Health Check Fails
**Symptoms:** Targets showing as unhealthy
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn $ALB_TG_ARN

# Verify security group rules
# ALB SG should allow port 80 from 0.0.0.0/0
# ECS SG should allow port 8080 from ALB SG

# Test container health locally
docker run -p 8080:8080 $ECR_REPO:latest
curl http://localhost:8080/
```

#### 6. Frontend "Failed to fetch" Error
**Symptoms:** Game loads but can't connect to API
```bash
# Check browser console for API URL
# Verify API is accessible
curl $API_URL

# Check CORS configuration in app.py
# Verify environment variable in build logs
```

## 🔧 Management Commands

### Deployment Management
```bash
# Complete deployment
./scripts/run.sh deploy

# Check status
./scripts/run.sh status

# Trigger manual build
./scripts/run.sh trigger-build

# Test deployment
./scripts/run.sh test-deployment
```

### Monitoring
```bash
# View ECS logs
aws logs tail "/ecs/project-name" --follow

# Monitor pipeline
aws codepipeline get-pipeline-state --name pipeline-name

# Check build history
aws codebuild list-builds-for-project --project-name build-project
```

### Debugging
```bash
# Check service health
aws ecs describe-services --cluster cluster-name --services service-name

# View load balancer targets
aws elbv2 describe-target-health --target-group-arn target-group-arn

# Check S3 deployment
aws s3 ls s3://bucket-name --recursive
```

## 💰 Cost Optimization

### Estimated Monthly Costs
- **ECS Fargate (256 CPU, 512MB):** ~$15-20
- **Application Load Balancer:** ~$16
- **S3 Storage (1GB):** ~$0.02
- **ECR Storage (1GB):** ~$0.10
- **CodePipeline:** ~$1
- **Data Transfer:** ~$1-5
- **Total:** ~$33-42/month

### Cost Reduction Tips
1. **Use smaller ECS task sizes** for development
2. **Stop ECS service** when not in use
3. **Clean up old ECR images** regularly
4. **Monitor data transfer** costs
5. **Use destroy script** for temporary deployments

## 🧹 Cleanup

### Complete Cleanup
```bash
# Destroy all infrastructure
cd infrastructure/
terraform destroy
# Type 'yes' when prompted

# Clean up local Docker images
docker rmi 2048-game-local
docker rmi $ECR_REPO:latest

# Remove local build artifacts
rm -rf frontend/node_modules/
rm -rf frontend/dist/
```

### Partial Cleanup (Keep Infrastructure)
```bash
# Stop ECS service (saves costs)
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --desired-count 0

# Empty S3 bucket
aws s3 rm s3://$S3_BUCKET --recursive
```

## 📊 Success Criteria

### Deployment Success Indicators
- ✅ Terraform apply completes without errors
- ✅ ECS service shows 1/1 running tasks
- ✅ Load balancer targets are healthy
- ✅ API responds at ALB endpoint
- ✅ Frontend loads from S3 website
- ✅ Game functions correctly (new game, moves, score)
- ✅ Pipeline triggers on git push
- ✅ Automated deployment completes successfully

### Performance Benchmarks
- **API Response Time:** <100ms
- **Frontend Load Time:** <3 seconds
- **Pipeline Execution:** <10 minutes
- **Service Availability:** 99.9% uptime

## 📞 Support

### Getting Help
- **AWS Documentation:** [ECS](https://docs.aws.amazon.com/ecs/), [CodePipeline](https://docs.aws.amazon.com/codepipeline/)
- **Terraform Registry:** [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **Project Issues:** Create issue in repository

### Useful Commands Reference
```bash
# Quick health check
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE \
  --query "services[0].{status:status,running:runningCount,desired:desiredCount}"

# Force new deployment
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment

# Check pipeline status
aws codepipeline get-pipeline-state --name $PIPELINE_NAME \
  --query "stageStates[*].{stage:stageName,status:latestExecution.status}"

# View recent logs
aws logs tail "/ecs/project-name" --since 1h
```

---

**🎯 Remember:** This deployment creates AWS resources that incur costs. Monitor usage and clean up when not needed.

**🎉 Success:** Once deployed, you'll have a production-ready 2048 game with automated CI/CD pipeline!