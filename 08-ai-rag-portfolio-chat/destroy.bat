@echo off
setlocal enabledelayedexpansion

echo ========================================
echo AWS RAG Portfolio Chat - DESTROY
echo ========================================

set AWS_REGION=ap-south-1
set AWS_ACCOUNT_ID=982534384941
set PROJECT_NAME=08-rag-portfolio-chat-aws-portfolio
set ECR_REPO=%PROJECT_NAME%-repo
set IMAGE_TAG=latest

echo [1/3] Destroying Terraform infrastructure...
cd infrastructure
terraform destroy -auto-approve -var="image_uri=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%"
if errorlevel 1 (
    echo WARNING: Terraform destroy had issues, continuing...
)

echo [2/3] Deleting ECR images...
aws ecr list-images --repository-name %ECR_REPO% --region %AWS_REGION% --query "imageIds[*]" --output json > images.json 2>nul
if exist images.json (
    for /f "delims=" %%i in (images.json) do set IMAGES=%%i
    if not "!IMAGES!"=="[]" (
        aws ecr batch-delete-image --repository-name %ECR_REPO% --region %AWS_REGION% --image-ids file://images.json
    )
    del images.json
)

echo [3/3] Deleting ECR repository...
aws ecr delete-repository --repository-name %ECR_REPO% --region %AWS_REGION% --force
if errorlevel 1 (
    echo WARNING: ECR repository deletion failed or already deleted
)

echo [CLEANUP] Removing local Docker images...
docker rmi %ECR_REPO%:latest 2>nul
docker rmi %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:latest 2>nul

echo ========================================
echo DESTRUCTION COMPLETED!
echo ========================================

pause