#!/bin/bash

# Get outputs from terraform
ECR_REPO=$(terraform -chdir=infrastructure output -raw ecr_repository_url)
ECS_CLUSTER=$(terraform -chdir=infrastructure output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform -chdir=infrastructure output -raw ecs_service_name)
AWS_REGION=$(terraform -chdir=infrastructure output -raw aws_region)

echo "ECR Repository: $ECR_REPO"
echo "ECS Cluster: $ECS_CLUSTER"
echo "ECS Service: $ECS_SERVICE"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Build and push initial image
docker build -f docker/Dockerfile -t $ECR_REPO:latest .
docker push $ECR_REPO:latest

# Update ECS service
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment

echo "Initial deployment complete!"
echo "API URL: $(terraform -chdir=infrastructure output -raw api_url)"