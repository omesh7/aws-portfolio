@echo off
REM Project 10 - Kinesis ECR ML Pipeline Local Deployment Script (Windows)

echo 🚀 Starting local deployment for Project 10 - Kinesis ECR ML Pipeline

REM Check if we're in the right directory
if not exist "10-KInesis-ECR-ML" (
    echo ❌ Please run this script from the aws-portfolio root directory
    exit /b 1
)

cd 10-KInesis-ECR-ML

REM Set timestamp for image tag
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%%dt:~4,2%%dt:~6,2%-%dt:~8,2%%dt:~10,2%"
echo Using image tag: %timestamp%

REM Setup ECR repository first
echo 🏗️ Setting up ECR repository...
cd state-file-infra
if not exist ".terraform" (
    echo 🔧 Initializing Terraform for ECR...
    terraform init
)
terraform apply -auto-approve -var="project_name=10-kinesis-ecr-ml-local"

REM Get ECR repository URL
for /f "tokens=*" %%i in ('terraform output -raw ecr_repo_uri') do set ECR_URL=%%i
echo ECR Repository URL: %ECR_URL%

cd ..

REM Build and push Docker image
echo 🐳 Building and pushing Docker image...
cd producer

REM Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin %ECR_URL%

REM Build and tag image
docker build -t %ECR_URL%:%timestamp% .
docker build -t %ECR_URL%:latest .

REM Push image
docker push %ECR_URL%:%timestamp%
docker push %ECR_URL%:latest

cd ..

REM Build Lambda package
echo 📦 Building Lambda package...
cd lambda
if exist lambda-package.zip del lambda-package.zip
powershell -command "Compress-Archive -Path * -DestinationPath lambda-package.zip -Force"
cd ..

REM Deploy infrastructure
echo 🏗️ Deploying infrastructure...
cd infrastructure

REM Initialize Terraform if needed
if not exist ".terraform" (
    echo 🔧 Initializing Terraform...
    terraform init
)

REM Apply Terraform configuration
terraform apply -auto-approve ^
    -var="environment=local" ^
    -var="project_name=10-kinesis-ecr-ml-local" ^
    -var="ecr_repository_url=%ECR_URL%" ^
    -var="image_version=%timestamp%"

echo ✅ Deployment completed!
echo 📋 Outputs:
terraform output -json

cd ..