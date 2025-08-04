@echo off

echo Destroying Multi-Cloud Weather Tracker
echo ==========================================

where terraform >nul 2>&1
if errorlevel 1 (
    echo Terraform required
    exit /b 1
)

cd /d "%~dp0..\..\terraform"

echo Destroying infrastructure...
terraform destroy -auto-approve

echo Infrastructure destroyed!