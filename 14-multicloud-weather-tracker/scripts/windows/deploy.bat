@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Multi-Cloud Weather Tracker Deployment
echo ==========================================
echo.

REM Get absolute path to project root (works from any directory)
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."
if not exist "%PROJECT_ROOT%\infrastructure" (
    set "PROJECT_ROOT=%SCRIPT_DIR%..\..\14-multicloud-weather-tracker"
)
if not exist "%PROJECT_ROOT%" (
    echo Error: Cannot find project root directory
    echo Current script location: %SCRIPT_DIR%
    pause
    exit /b 1
)

echo Project root: %PROJECT_ROOT%
echo.

REM Check prerequisites
echo Checking prerequisites...
where terraform >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Terraform is required but not found in PATH
    echo Please install Terraform: https://terraform.io/downloads
    pause
    exit /b 1
)
echo [OK] Terraform found

where aws >nul 2>&1
if errorlevel 1 (
    echo [ERROR] AWS CLI is required but not found in PATH
    echo Please install AWS CLI: https://aws.amazon.com/cli/
    pause
    exit /b 1
)
echo [OK] AWS CLI found

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo [ERROR] AWS credentials not configured
    echo Please run: aws configure
    pause
    exit /b 1
)
echo [OK] AWS credentials configured

echo.

REM Navigate to infrastructure directory
set "INFRA_DIR=%PROJECT_ROOT%\infrastructure"
if not exist "%INFRA_DIR%" (
    echo [ERROR] Infrastructure directory not found: %INFRA_DIR%
    pause
    exit /b 1
)

cd /d "%INFRA_DIR%"
echo Working directory: %CD%
echo.

REM Check for terraform.tfvars
if not exist "terraform.tfvars" (
    echo [WARNING] terraform.tfvars not found
    echo Please copy terraform.tfvars.example to terraform.tfvars and configure it
    if exist "terraform.tfvars.example" (
        echo Example file found at: %INFRA_DIR%\terraform.tfvars.example
    )
    pause
    exit /b 1
)

echo [1/4] Initializing Terraform...
terraform init
if errorlevel 1 (
    echo [ERROR] Terraform initialization failed
    pause
    exit /b 1
)
echo.

echo [2/4] Planning deployment...
terraform plan
if errorlevel 1 (
    echo [ERROR] Terraform plan failed
    pause
    exit /b 1
)
echo.

echo [3/4] Deploying infrastructure...
echo.
echo Multi-Cloud Deployment Options:
echo   - AWS + GCP (Parallel): Both clouds deploy simultaneously
echo   - AWS Only: Deploy only AWS infrastructure
echo   - Current config: Both AWS and GCP are enabled
echo.
echo Note: GCP APIs will be enabled automatically (may take 2-3 minutes)
echo.
terraform apply -auto-approve
if errorlevel 1 (
    echo [ERROR] Terraform apply failed
    echo.
    echo Troubleshooting:
    echo - GCP APIs may need time to propagate (wait 2-3 minutes and retry)
    echo - Check GCP credentials: gcloud auth application-default login
    echo - Verify gcp_project_id in terraform.tfvars
    echo - Enable billing on GCP project if not already enabled
    pause
    exit /b 1
)
echo.

echo [4/4] Deploying frontend...
REM Get outputs from Terraform
echo Getting Terraform outputs...
terraform output -raw aws_s3_bucket > temp_bucket.txt 2>nul
set /p AWS_BUCKET=<temp_bucket.txt
del temp_bucket.txt 2>nul

terraform output -raw aws_lambda_function_url_weather_tracker_url > temp_lambda.txt 2>nul
set /p LAMBDA_URL=<temp_lambda.txt
del temp_lambda.txt 2>nul

if "!AWS_BUCKET!"=="" (
    echo [ERROR] Could not get S3 bucket name from Terraform output
    pause
    exit /b 1
)

if "!LAMBDA_URL!"=="" (
    echo [ERROR] Could not get Lambda URL from Terraform output
    pause
    exit /b 1
)

echo S3 Bucket: !AWS_BUCKET!
echo Lambda URL: !LAMBDA_URL!
echo.

REM Prepare frontend files
set "FRONTEND_DIR=%PROJECT_ROOT%\frontend"
set "TEMP_DIR=%PROJECT_ROOT%\temp-frontend"

if not exist "%FRONTEND_DIR%" (
    echo [ERROR] Frontend directory not found: %FRONTEND_DIR%
    pause
    exit /b 1
)

echo Preparing frontend files...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
xcopy "%FRONTEND_DIR%\*" "%TEMP_DIR%\" /e /y /q

REM Update API configuration
echo window.LAMBDA_API_URL = '!LAMBDA_URL!api/weather'; > "%TEMP_DIR%\config.js"

REM Deploy to S3
echo Uploading to S3...
aws s3 sync "%TEMP_DIR%\" s3://!AWS_BUCKET!/ --delete
if errorlevel 1 (
    echo [ERROR] S3 sync failed
    rmdir /s /q "%TEMP_DIR%"
    pause
    exit /b 1
)

REM Cleanup
rmdir /s /q "%TEMP_DIR%"

echo.
echo ==========================================
echo Deployment completed successfully!
echo ==========================================
terraform output -raw weather_app_url > temp_url.txt 2>nul
set /p WEATHER_URL=<temp_url.txt
del temp_url.txt 2>nul
if not "!WEATHER_URL!"=="" (
    echo.
    echo Application URL: !WEATHER_URL!
    echo.
)

echo Press any key to exit...
pause >nul