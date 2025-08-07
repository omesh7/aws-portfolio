@echo off
setlocal enabledelayedexpansion

echo ========================================
echo AWS RAG Portfolio Chat - DEPLOY
echo ========================================

set AWS_REGION=ap-south-1
set AWS_ACCOUNT_ID=982534384941
set PROJECT_NAME=08-rag-portfolio-chat-aws-portfolio
set ECR_REPO=%PROJECT_NAME%-repo
set IMAGE_TAG=latest

echo [1/6] Creating ECR repository...
aws ecr describe-repositories --repository-names %ECR_REPO% --region %AWS_REGION% >nul 2>&1
if errorlevel 1 (
    aws ecr create-repository --repository-name %ECR_REPO% --region %AWS_REGION%
    if errorlevel 1 (
        echo ERROR: Failed to create ECR repository
        exit /b 1
    )
)

echo [2/6] Getting ECR login token...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
if errorlevel 1 (
    echo ERROR: Failed to login to ECR
    exit /b 1
)

echo [3/6] Building Docker image...
cd lambda
docker system prune -f
docker buildx build --no-cache --platform linux/amd64 --provenance=false -t %ECR_REPO%:%IMAGE_TAG% .
if errorlevel 1 (
    echo ERROR: Failed to build Docker image
    exit /b 1
)

echo [4/6] Tagging image for ECR...
docker tag %ECR_REPO%:%IMAGE_TAG% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%

echo [5/6] Pushing image to ECR...
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
if errorlevel 1 (
    echo ERROR: Failed to push image to ECR
    exit /b 1
)

echo [6/6] Deploying infrastructure with Terraform...
cd ..\infrastructure
terraform init
if errorlevel 1 (
    echo ERROR: Terraform init failed
    exit /b 1
)

terraform plan -var="image_uri=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%"
if errorlevel 1 (
    echo ERROR: Terraform plan failed
    exit /b 1
)

terraform apply -auto-approve -var="image_uri=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%"
if errorlevel 1 (
    echo ERROR: Terraform apply failed
    exit /b 1
)

echo ========================================
echo DEPLOYMENT COMPLETED SUCCESSFULLY!
echo ========================================
terraform output

pause