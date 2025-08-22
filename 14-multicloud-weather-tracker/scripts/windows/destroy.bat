@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Multi-Cloud Weather Tracker - DESTROY
echo ==========================================
echo.
echo WARNING: This will permanently delete all resources!
echo.
set /p "CONFIRM=Type 'yes' to confirm destruction: "
if /i not "!CONFIRM!"=="yes" (
    echo Destruction cancelled.
    pause
    exit /b 0
)
echo.

REM Get absolute path to project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\..\14-multicloud-weather-tracker"
if not exist "%PROJECT_ROOT%" (
    set "PROJECT_ROOT=%SCRIPT_DIR%..\.."
)
if not exist "%PROJECT_ROOT%" (
    echo Error: Cannot find project root directory
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
    pause
    exit /b 1
)
echo [OK] Terraform found

where aws >nul 2>&1
if errorlevel 1 (
    echo [ERROR] AWS CLI is required but not found in PATH
    pause
    exit /b 1
)
echo [OK] AWS CLI found
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

REM Get S3 bucket name before destroying (for cleanup)
echo Getting resource information...
for /f "tokens=*" %%i in ('terraform output -raw aws_s3_bucket 2^>nul') do set AWS_BUCKET=%%i

if not "!AWS_BUCKET!"=="" (
    echo Found S3 bucket: !AWS_BUCKET!
    echo Emptying S3 bucket before destruction...
    aws s3 rm s3://!AWS_BUCKET!/ --recursive
    if errorlevel 1 (
        echo [WARNING] Failed to empty S3 bucket, continuing with destruction...
    ) else (
        echo [OK] S3 bucket emptied
    )
) else (
    echo [INFO] No S3 bucket found in Terraform state
)
echo.

echo Destroying infrastructure...
terraform destroy -auto-approve
if errorlevel 1 (
    echo [ERROR] Terraform destroy failed
    echo You may need to manually clean up some resources
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Infrastructure destroyed successfully!
echo ==========================================
echo.
echo Press any key to exit...
pause >nul