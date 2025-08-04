@echo off
setlocal enabledelayedexpansion

echo Multi-Cloud Weather Tracker Deployment
echo ==========================================

where terraform >nul 2>&1
if errorlevel 1 (
    echo Terraform required
    exit /b 1
)

where aws >nul 2>&1
if errorlevel 1 (
    echo AWS CLI required
    exit /b 1
)

cd /d "%~dp0..\..\terraform"

echo Initializing Terraform...
terraform init

echo Deploying infrastructure...
terraform apply -auto-approve

for /f "tokens=*" %%i in ('terraform output -raw aws_s3_bucket') do set AWS_BUCKET=%%i
for /f "tokens=*" %%i in ('terraform output -raw aws_lambda_function_url_weather_tracker_url') do set LAMBDA_URL=%%i

echo Updating API configuration...
set PROJ_DIR=%~dp0..\..
if exist "%PROJ_DIR%\temp-frontend" rmdir /s /q "%PROJ_DIR%\temp-frontend"
mkdir "%PROJ_DIR%\temp-frontend"
xcopy "%PROJ_DIR%\frontend\*" "%PROJ_DIR%\temp-frontend\" /e /y
echo window.LAMBDA_API_URL = '!LAMBDA_URL!api/weather'; > "%PROJ_DIR%\temp-frontend\api-config.js"

echo Deploying frontend...
aws s3 sync "%PROJ_DIR%\temp-frontend\" s3://!AWS_BUCKET!/ --delete
rmdir /s /q "%PROJ_DIR%\temp-frontend"

echo Deployment completed!
for /f "tokens=*" %%i in ('terraform output -raw weather_app_url') do echo URL: %%i