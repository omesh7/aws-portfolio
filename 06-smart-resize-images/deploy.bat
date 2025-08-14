@echo off
REM Project 06 - Smart Image Resizer Local Deployment Script (Windows)

echo  Starting local deployment for Project 06 - Smart Image Resizer

REM Check if we're in the right directory
if not exist "06-smart-resize-images" (
    echo  Please run this script from the aws-portfolio root directory
    exit /b 1
)

cd 06-smart-resize-images

REM Build Lambda package locally
echo  Building Lambda package...
cd lambda
call npm ci --production --omit=dev
cd ..

REM Deploy infrastructure
echo  Deploying infrastructure...
cd infrastructure

REM Initialize Terraform if needed
if not exist ".terraform" (
    echo  Initializing Terraform...
    terraform init
)

REM Check if Vercel token is set
if "%VERCEL_API_TOKEN%"=="" (
    echo   VERCEL_API_TOKEN not set - deploying AWS only
    terraform apply -auto-approve -var="environment=local" -var="vercel_api_token="
) else (
    echo  Deploying AWS + Vercel...
    terraform apply -auto-approve -var="environment=local" -var="vercel_api_token=%VERCEL_API_TOKEN%"
)

echo  Deployment completed!
echo  Outputs:
terraform output -json