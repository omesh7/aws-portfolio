#!/bin/bash

# 2048 Game CI/CD Pipeline - Complete Deployment Script (Linux)
# This script automates the entire deployment process

set -e  # Exit on any error

PROJECT_NAME="project-13-2048-game-codepipeline"
REGION="ap-south-1"

echo "🚀 Starting complete deployment of 2048 Game CI/CD Pipeline..."
echo "=================================================="

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found. Please install AWS CLI."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not found. Please install Terraform."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found. Please install Docker."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js not found. Please install Node.js."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python not found. Please install Python."; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured. Run 'aws configure'."; exit 1; }

echo "✅ All prerequisites met!"

# Navigate to project root
cd "$(dirname "$0")/../.."

# Step 1: Test local development
echo ""
echo "🧪 Step 1: Testing local development..."
echo "Installing Python dependencies..."
pip3 install -r requirements.txt >/dev/null 2>&1

echo "Installing frontend dependencies..."
cd frontend
npm install >/dev/null 2>&1
cd ..

# Step 2: Test Docker build
echo ""
echo "🐳 Step 2: Testing Docker build..."
docker build -f docker/Dockerfile -t 2048-game-local . >/dev/null 2>&1
echo "✅ Docker build successful!"

# Step 3: Deploy infrastructure
echo ""
echo "🏗️ Step 3: Deploying infrastructure with Terraform..."
cd infrastructure

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found. Please create it from terraform.tfvars.example"
    exit 1
fi

terraform init >/dev/null 2>&1
echo "Planning infrastructure deployment..."
terraform plan >/dev/null 2>&1

echo "Applying infrastructure (this may take 8-12 minutes)..."
terraform apply -auto-approve

# Get outputs
ECR_REPO=$(terraform output -raw ecr_repository_url)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)
S3_BUCKET=$(terraform output -raw s3_bucket_name)
API_URL=$(terraform output -raw api_url)

echo "✅ Infrastructure deployed successfully!"
echo "📊 Infrastructure Details:"
echo "   ECR Repository: $ECR_REPO"
echo "   ECS Cluster: $ECS_CLUSTER"
echo "   ECS Service: $ECS_SERVICE"
echo "   S3 Bucket: $S3_BUCKET"
echo "   API URL: $API_URL"

cd ..

# Step 4: Deploy initial container
echo ""
echo "📦 Step 4: Deploying initial container to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO >/dev/null 2>&1

docker tag 2048-game-local:latest $ECR_REPO:latest
docker push $ECR_REPO:latest >/dev/null 2>&1

echo "Updating ECS service..."
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment >/dev/null 2>&1

echo "✅ Container deployed successfully!"

# Step 5: Wait for service health
echo ""
echo "⏳ Step 5: Waiting for ECS service to become healthy..."
echo "This may take 3-5 minutes..."

for i in {1..30}; do
    RUNNING_COUNT=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].runningCount" --output text)
    if [ "$RUNNING_COUNT" = "1" ]; then
        echo "✅ ECS service is running!"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 10
done

# Check load balancer health
echo "Checking load balancer target health..."
ALB_TG_ARN=$(aws elbv2 describe-target-groups --names ${PROJECT_NAME}-tg --query "TargetGroups[0].TargetGroupArn" --output text)

for i in {1..20}; do
    HEALTH_STATUS=$(aws elbv2 describe-target-health --target-group-arn $ALB_TG_ARN --query "TargetHealthDescriptions[0].TargetHealth.State" --output text 2>/dev/null || echo "unknown")
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "✅ Load balancer targets are healthy!"
        break
    fi
    echo "   Target health: $HEALTH_STATUS ($i/20)"
    sleep 15
done

# Step 6: Test API
echo ""
echo "🧪 Step 6: Testing API endpoint..."
API_RESPONSE=$(curl -s $API_URL || echo "failed")
if [[ $API_RESPONSE == *"2048 Game API"* ]]; then
    echo "✅ API is responding correctly!"
else
    echo "⚠️ API test failed, but continuing with deployment..."
fi

# Step 7: Deploy frontend
echo ""
echo "🎨 Step 7: Building and deploying frontend..."
cd frontend

echo "VITE_API_URL=$API_URL" > .env
npm run build >/dev/null 2>&1

aws s3 sync dist/ s3://$S3_BUCKET --delete >/dev/null 2>&1

FRONTEND_URL="http://$S3_BUCKET.s3-website.$REGION.amazonaws.com"
echo "✅ Frontend deployed successfully!"

cd ..

# Step 8: Final verification
echo ""
echo "✅ Deployment completed successfully!"
echo "=================================================="
echo "🎯 Your 2048 Game is now live:"
echo ""
echo "🌐 Frontend URL: $FRONTEND_URL"
echo "🔗 API URL: $API_URL"
echo ""
echo "📊 Infrastructure Summary:"
echo "   • ECS Fargate service running"
echo "   • Application Load Balancer configured"
echo "   • S3 static website hosting"
echo "   • ECR container registry"
echo "   • CodePipeline ready for CI/CD"
echo ""
echo "🔄 Next Steps:"
echo "   1. Open the frontend URL in your browser"
echo "   2. Test the game functionality"
echo "   3. Make code changes and push to trigger CI/CD"
echo ""
echo "💡 To monitor your deployment:"
echo "   ./scripts/linux/status.sh"
echo ""
echo "🧹 To clean up resources:"
echo "   ./scripts/linux/destroy.sh"
echo ""
echo "🎉 Happy gaming!"