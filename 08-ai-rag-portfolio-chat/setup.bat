@echo off
echo ========================================
echo AWS RAG Portfolio Chat - SETUP
echo ========================================

echo Checking prerequisites...

echo [1/4] Checking AWS CLI...
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI not found. Please install AWS CLI.
    exit /b 1
)

echo [2/4] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found. Please install Docker.
    exit /b 1
)

echo [3/4] Checking Terraform...
terraform --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Terraform not found. Please install Terraform.
    exit /b 1
)

echo [4/4] Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS credentials not configured. Run 'aws configure'.
    exit /b 1
)

echo ========================================
echo SETUP COMPLETE! Ready to deploy.
echo ========================================
echo Run 'deploy.bat' to deploy the infrastructure
echo Run 'destroy.bat' to destroy everything

pause