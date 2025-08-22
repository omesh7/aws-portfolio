@echo off
echo ========================================
echo Project 01 - Local Terraform Test
echo ========================================

cd /d "%~dp0\infrastructure"

echo.
echo 🔧 Initializing Terraform...
terraform init -backend=false
if %errorlevel% neq 0 (
    echo ❌ Terraform init failed
    pause
    exit /b 1
)

echo.
echo ✅ Validating Terraform configuration...
terraform validate
if %errorlevel% neq 0 (
    echo ❌ Terraform validation failed
    pause
    exit /b 1
)

echo.
echo 📋 Planning Terraform deployment (without Cloudflare)...
terraform plan -var="enable_custom_domain=false" -var="environment=local"
if %errorlevel% neq 0 (
    echo ❌ Terraform plan failed
    pause
    exit /b 1
)

echo.
echo ✅ Terraform configuration is valid!
echo Ready for deployment with: terraform apply

pause