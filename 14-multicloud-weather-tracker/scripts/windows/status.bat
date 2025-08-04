@echo off
setlocal enabledelayedexpansion

echo Multi-Cloud Weather Tracker Status
echo ===================================

cd /d "%~dp0..\..\terraform"

if not exist terraform.tfstate (
    echo No deployment found
    exit /b 1
)

echo Infrastructure Status:
echo Lambda: Deployed

for /f "tokens=*" %%i in ('terraform output -raw weather_app_url 2^>nul') do set WEATHER_URL=%%i
if "!WEATHER_URL!"=="" set WEATHER_URL=Not available
echo Weather App: !WEATHER_URL!

echo.
echo Testing endpoints...
for /f "tokens=*" %%i in ('terraform output -raw aws_lambda_function_url_weather_tracker_url 2^>nul') do set LAMBDA_URL=%%i
if not "!LAMBDA_URL!"=="" (
    curl -s -o nul -w "%%{http_code}" "!LAMBDA_URL!api/weather?city=london" > temp_status.txt 2>nul
    set /p HTTP_CODE=<temp_status.txt
    del temp_status.txt 2>nul
    if "!HTTP_CODE!"=="200" (
        echo API: Working
    ) else (
        echo API: Failed
    )
) else (
    echo API: URL not found
)