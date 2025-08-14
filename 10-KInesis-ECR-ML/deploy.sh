#!/bin/bash

# Project 10 - Kinesis ECR ML Pipeline Local Deployment Script

set -e

echo "🚀 Starting local deployment for Project 10 - Kinesis ECR ML Pipeline"

# Check if we're in the right directory
if [ ! -d "10-KInesis-ECR-ML" ]; then
    echo "❌ Please run this script from the aws-portfolio root directory"
    exit 1
fi

cd 10-KInesis-ECR-ML

# Set timestamp for image tag
TIMESTAMP=$(date +%Y%m%d-%H%M)
echo "Using image tag: $TIMESTAMP"

# Setup ECR repository first
echo "🏗️ Setting up ECR repository..."
cd state-file-infra
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform for ECR..."
    terraform init
fi
terraform apply -auto-approve -var="project_name=10-kinesis-ecr-ml-local"

# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repo_uri)
echo "ECR Repository URL: $ECR_URL"

cd ..

# Build and push Docker image
echo "🐳 Building and pushing Docker image..."
cd producer

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_URL

# Build and tag image
docker build -t $ECR_URL:$TIMESTAMP .
docker build -t $ECR_URL:latest .

# Push image
docker push $ECR_URL:$TIMESTAMP
docker push $ECR_URL:latest

cd ..

# Build Lambda package
echo "📦 Building Lambda package..."
cd lambda
rm -f lambda-package.zip
zip -r lambda-package.zip . -x "*.git*" "*.md" "*.txt" "__pycache__/*"
cd ..

# Deploy infrastructure
echo "🏗️ Deploying infrastructure..."
cd infrastructure

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Apply Terraform configuration
terraform apply -auto-approve \
    -var="environment=local" \
    -var="project_name=10-kinesis-ecr-ml-local" \
    -var="ecr_repository_url=$ECR_URL" \
    -var="image_version=$TIMESTAMP"

echo "✅ Deployment completed!"
echo "📋 Outputs:"
terraform output -json | jq '.'

cd ..