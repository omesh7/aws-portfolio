@echo off
echo ========================================
echo Project 01 - Static Website Local Deploy
echo ========================================

cd /d "%~dp0"

echo.
echo 📦 Installing site dependencies...
cd site
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo 🏗️ Building site...
call npm run build
if %errorlevel% neq 0 (
    echo ❌ Failed to build site
    pause
    exit /b 1
)

echo.
echo 🚀 Deploying infrastructure...
cd ..\infrastructure

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ❌ Terraform init failed
    pause
    exit /b 1
)

echo Applying Terraform configuration...
terraform apply -var="environment=local" -var="upload_site_files=true"
if %errorlevel% neq 0 (
    echo ❌ Terraform apply failed
    pause
    exit /b 1
)

echo.
echo ✅ Deployment completed successfully!
echo.
echo 📋 Outputs:
terraform output

pause