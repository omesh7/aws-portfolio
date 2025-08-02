#!/bin/bash

# Get ECR repository URL from terraform
ECR_REPO=$(terraform -chdir=infrastructure output -raw ecr_repository_url)
LAMBDA_FUNCTION=$(terraform -chdir=infrastructure output -raw lambda_function_name)
AWS_REGION=$(terraform -chdir=infrastructure output -raw aws_region || echo "ap-south-1")

echo "ECR Repository: $ECR_REPO"
echo "Lambda Function: $LAMBDA_FUNCTION"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Build and push initial image
docker build -f docker/Dockerfile -t $ECR_REPO:latest .
docker push $ECR_REPO:latest

# Update Lambda function
aws lambda update-function-code --function-name $LAMBDA_FUNCTION --image-uri $ECR_REPO:latest

echo "Initial deployment complete!"
echo "Lambda Function URL: $(terraform -chdir=infrastructure output -raw lambda_function_url)"