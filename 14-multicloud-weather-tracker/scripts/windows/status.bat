@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Multi-Cloud Weather Tracker - STATUS
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
        echo [INFO] No deployment found
        echo Run deploy.bat to create infrastructure
        pause
        exit /b 0
    )
)

where curl >nul 2>&1
set CURL_AVAILABLE=1
if errorlevel 1 set CURL_AVAILABLE=0

echo ==========================================
echo INFRASTRUCTURE STATUS
echo ==========================================
echo.

echo Getting deployment information...
terraform output -raw weather_app_url > temp1.txt 2>nul
set /p WEATHER_URL=<temp1.txt
del temp1.txt 2>nul

terraform output -raw aws_lambda_function_url_weather_tracker_url > temp2.txt 2>nul
set /p LAMBDA_URL=<temp2.txt
del temp2.txt 2>nul

terraform output -raw aws_s3_bucket > temp3.txt 2>nul
set /p S3_BUCKET=<temp3.txt
del temp3.txt 2>nul

terraform output -raw aws_cloudfront_distribution_domain_name > temp4.txt 2>nul
set /p CLOUDFRONT_URL=<temp4.txt
del temp4.txt 2>nul

terraform output -raw gcp_load_balancer_ip > temp5.txt 2>nul
set /p GCP_LB_IP=<temp5.txt
del temp5.txt 2>nul

terraform output -raw weather_app_backup_url > temp6.txt 2>nul
set /p GCP_BACKUP_URL=<temp6.txt
del temp6.txt 2>nul

echo Resources:
if not "!S3_BUCKET!"=="" (
    echo   S3 Bucket: !S3_BUCKET!
) else (
    echo   S3 Bucket: [Not found]
)

if not "!CLOUDFRONT_URL!"=="" (
    echo   CloudFront: !CLOUDFRONT_URL!
) else (
    echo   CloudFront: [Not found]
)

if not "!LAMBDA_URL!"=="" (
    echo   Lambda API: !LAMBDA_URL!
) else (
    echo   Lambda API: [Not found]
)

if not "!WEATHER_URL!"=="" (
    echo   Weather App (Primary): !WEATHER_URL!
) else (
    echo   Weather App (Primary): [Not available]
)

echo.
echo Google Cloud Resources:
if not "!GCP_LB_IP!"=="" (
    echo   Load Balancer IP: !GCP_LB_IP!
) else (
    echo   Load Balancer IP: [Not found]
)

if not "!GCP_BACKUP_URL!"=="" (
    echo   Backup App URL: !GCP_BACKUP_URL!
) else (
    echo   Backup App URL: [Not available]
)

echo.
echo ==========================================
echo ENDPOINT TESTING
echo ==========================================
echo.

if !CURL_AVAILABLE!==0 (
    echo [WARNING] curl not found - cannot test endpoints
    echo Install curl to enable endpoint testing
    goto :end
)

if not "!LAMBDA_URL!"=="" (
    echo Testing Lambda API...
    curl -s -o nul -w "%%{http_code}" "!LAMBDA_URL!api/weather?city=london" > temp5.txt 2>nul
    if exist temp5.txt (
        set /p HTTP_CODE=<temp5.txt
        del temp5.txt 2>nul
        if "!HTTP_CODE!"=="200" (
            echo   Lambda API: Working (HTTP !HTTP_CODE!)
        ) else (
            echo   Lambda API: Failed (HTTP !HTTP_CODE!)
        )
    ) else (
        echo   Lambda API: Test failed
    )
) else (
    echo   Lambda API: URL not available
)

if not "!WEATHER_URL!"=="" (
    echo Testing Primary Weather App...
    curl -s -o nul -w "%%{http_code}" "!WEATHER_URL!" > temp7.txt 2>nul
    if exist temp7.txt (
        set /p HTTP_CODE=<temp7.txt
        del temp7.txt 2>nul
        if "!HTTP_CODE!"=="200" (
            echo   Primary Weather App: Working (HTTP !HTTP_CODE!)
        ) else (
            echo   Primary Weather App: Failed (HTTP !HTTP_CODE!)
        )
    ) else (
        echo   Primary Weather App: Test failed
    )
) else (
    echo   Primary Weather App: URL not available
)

if not "!GCP_BACKUP_URL!"=="" (
    echo Testing Backup Weather App...
    curl -s -o nul -w "%%{http_code}" "!GCP_BACKUP_URL!" > temp8.txt 2>nul
    if exist temp8.txt (
        set /p HTTP_CODE=<temp8.txt
        del temp8.txt 2>nul
        if "!HTTP_CODE!"=="200" (
            echo   Backup Weather App: Working (HTTP !HTTP_CODE!)
        ) else (
            echo   Backup Weather App: Failed (HTTP !HTTP_CODE!)
        )
    ) else (
        echo   Backup Weather App: Test failed
    )
) else (
    echo   Backup Weather App: URL not available
)

:end
echo.
echo ==========================================
echo STATUS CHECK COMPLETE
echo ==========================================
echo.
echo Press any key to exit...
pause >nul