@echo off
setlocal enabledelayedexpansion

echo Testing Multi-Cloud Failover
echo =============================

cd /d "%~dp0..\..\terraform"

for /f "tokens=*" %%i in ('terraform output -raw weather_app_url 2^>nul') do set WEATHER_URL=%%i
for /f "tokens=*" %%i in ('terraform output -raw aws_lambda_function_url_weather_tracker_url 2^>nul') do set LAMBDA_URL=%%i

if "!WEATHER_URL!"=="" (
    echo Deployment not found
    exit /b 1
)

echo Testing primary endpoint...
curl -s -o nul -w "%%{http_code}" "!LAMBDA_URL!api/weather?city=london" > temp_failover.txt 2>nul
set /p HTTP_CODE=<temp_failover.txt
del temp_failover.txt 2>nul

if "!HTTP_CODE!"=="200" (
    echo Primary AWS Lambda: Working
    set STATUS=Online
) else (
    echo Primary AWS Lambda: Failed
    set STATUS=Offline
)

echo.
echo Frontend URL: !WEATHER_URL!
echo API URL: !LAMBDA_URL!api/weather

echo.
echo Failover Test Results:
echo - Primary (AWS): !STATUS!
echo.
echo To test failover manually:
echo    1. Disable AWS Lambda function
echo    2. Check if traffic routes to backup
echo    3. Re-enable AWS Lambda