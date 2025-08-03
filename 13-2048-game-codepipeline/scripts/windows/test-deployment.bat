@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=proj-13-2048-game-cp
set REGION=ap-south-1

echo Testing 2048 Game deployment...
echo =================================

cd /d "%~dp0..\.."
cd infrastructure 2>nul || (
    echo No infrastructure directory found.
    exit /b 1
)

if not exist "terraform.tfstate" if not exist ".terraform\terraform.tfstate" (
    echo No Terraform state found. Infrastructure not deployed.
    exit /b 1
)

echo Getting deployment URLs...
for /f "tokens=*" %%i in ('terraform output -raw api_url 2^>nul ^|^| echo') do set API_URL=%%i
for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name 2^>nul ^|^| echo') do set S3_BUCKET=%%i

if "!API_URL!"=="" (
    echo API URL not found
    exit /b 1
)

set FRONTEND_URL=http://!S3_BUCKET!.s3-website.!REGION!.amazonaws.com

echo.
echo Testing API endpoint...
echo API URL: !API_URL!

for /f "tokens=*" %%i in ('curl -s --max-time 10 !API_URL! 2^>nul ^|^| echo failed') do set API_RESPONSE=%%i
echo !API_RESPONSE! | findstr "2048 Game API" >nul && (
    echo [PASS] API health check
) || (
    echo [FAIL] API health check - Response: !API_RESPONSE!
)

echo.
echo Testing game creation...
echo {"action":"new"} > temp_request.json
for /f "tokens=*" %%i in ('curl -s --max-time 10 -X POST -H "Content-Type: application/json" -d @temp_request.json !API_URL! 2^>nul ^|^| echo failed') do set GAME_RESPONSE=%%i
del temp_request.json >nul 2>&1

echo !GAME_RESPONSE! | findstr "success.*true" >nul && (
    echo [PASS] Game creation test
) || (
    echo [FAIL] Game creation test - Response: !GAME_RESPONSE!
)

echo.
echo Testing frontend deployment...
echo Frontend URL: !FRONTEND_URL!

for /f "tokens=*" %%i in ('curl -s --max-time 10 -I !FRONTEND_URL! 2^>nul ^| findstr "200 OK" ^|^| echo failed') do set FRONTEND_STATUS=%%i
if not "!FRONTEND_STATUS!"=="failed" (
    echo [PASS] Frontend accessibility
) else (
    echo [FAIL] Frontend accessibility
)

echo.
echo Testing S3 bucket contents...
for /f %%i in ('aws s3 ls s3://!S3_BUCKET! --recursive ^| find /c /v ""') do set FILE_COUNT=%%i
if !FILE_COUNT! gtr 0 (
    echo [PASS] Frontend files deployed (!FILE_COUNT! files)
) else (
    echo [FAIL] Frontend files missing
)

echo.
echo =================================
echo Test Summary:
echo   API URL: !API_URL!
echo   Frontend URL: !FRONTEND_URL!
echo.
echo Manual test steps:
echo   1. Open frontend URL in browser
echo   2. Click "New Game" button
echo   3. Use arrow keys to play
echo   4. Verify score updates

endlocal