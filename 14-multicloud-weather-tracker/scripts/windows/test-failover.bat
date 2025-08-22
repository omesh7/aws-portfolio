@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Multi-Cloud Weather Tracker - FAILOVER TEST
echo ==========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."

echo Project root: %PROJECT_ROOT%
echo.

set "INFRA_DIR=%PROJECT_ROOT%\infrastructure"
if not exist "%INFRA_DIR%" (
    echo [ERROR] Infrastructure directory not found
    pause
    exit /b 1
)

cd /d "%INFRA_DIR%"
echo Working directory: %CD%
echo.

echo Checking for Terraform state...
dir terraform.tfstate* 2>nul
if not exist "terraform.tfstate" (
    if not exist ".terraform\terraform.tfstate" (
        echo [ERROR] No deployment found
        echo Run deploy.bat first
        pause
        exit /b 1
    )
)

where curl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl required for testing
    pause
    exit /b 1
)

echo Getting deployment info...
terraform output -raw weather_app_url > temp1.txt 2>nul
set /p WEATHER_URL=<temp1.txt
del temp1.txt 2>nul

terraform output -raw aws_lambda_function_url_weather_tracker_url > temp2.txt 2>nul
set /p LAMBDA_URL=<temp2.txt
del temp2.txt 2>nul

if "!WEATHER_URL!"=="" (
    echo [ERROR] Weather app URL not found
    pause
    exit /b 1
)

echo ==========================================
echo ENDPOINT INFORMATION
echo ==========================================
echo.
echo Primary (AWS):
echo   Frontend: !WEATHER_URL!
if not "!LAMBDA_URL!"=="" echo   API: !LAMBDA_URL!api/weather
echo.
echo Secondary (Google Cloud):
echo   Status: Not deployed
echo.

echo ==========================================
echo FAILOVER TESTING
echo ==========================================
echo.

if not "!LAMBDA_URL!"=="" (
    echo Testing AWS Lambda API...
    curl -s -o nul -w "%%{http_code}" "!LAMBDA_URL!api/weather?city=london" > temp3.txt 2>nul
    if exist temp3.txt (
        set /p HTTP_CODE=<temp3.txt
        del temp3.txt 2>nul
        if "!HTTP_CODE!"=="200" (
            echo   AWS Lambda API: ONLINE
            set AWS_STATUS=ONLINE
        ) else (
            echo   AWS Lambda API: FAILED
            set AWS_STATUS=FAILED
        )
    ) else (
        echo   AWS Lambda API: ERROR
        set AWS_STATUS=ERROR
    )
) else (
    echo   AWS Lambda API: NOT FOUND
    set AWS_STATUS=NOT_FOUND
)

echo.
echo Testing AWS Frontend...
curl -s -o nul -w "%%{http_code}" "!WEATHER_URL!" > temp4.txt 2>nul
if exist temp4.txt (
    set /p HTTP_CODE=<temp4.txt
    del temp4.txt 2>nul
    if "!HTTP_CODE!"=="200" (
        echo   AWS Frontend: ONLINE
        set FRONTEND_STATUS=ONLINE
    ) else (
        echo   AWS Frontend: FAILED
        set FRONTEND_STATUS=FAILED
    )
) else (
    echo   AWS Frontend: ERROR
    set FRONTEND_STATUS=ERROR
)

echo.
echo ==========================================
echo FAILOVER TEST RESULTS
echo ==========================================
echo.
echo Primary (AWS):
echo   API Status: !AWS_STATUS!
echo   Frontend Status: !FRONTEND_STATUS!
echo.
echo Secondary (Google Cloud):
echo   Status: NOT DEPLOYED
echo.
echo To enable multi-cloud failover:
echo 1. Edit infrastructure/main.tf
echo 2. Uncomment GCP module section
echo 3. Set gcp_project_id in terraform.tfvars
echo 4. Run deploy.bat
echo.
echo Press any key to exit...
pause >nul