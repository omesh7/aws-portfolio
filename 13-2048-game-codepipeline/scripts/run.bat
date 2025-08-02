@echo off
setlocal enabledelayedexpansion

echo 2048 Game CI/CD Pipeline - Script Runner
echo ============================================
echo Platform: Windows
echo.

echo Available actions:
echo   1. deploy   - Deploy the complete infrastructure and application
echo   2. status   - Check the status of deployed resources
echo   3. destroy  - Destroy all resources and clean up
echo.

if "%1"=="" (
    set /p ACTION_NUM="Select an action (1-3): "
    if "!ACTION_NUM!"=="1" set ACTION=deploy
    if "!ACTION_NUM!"=="2" set ACTION=status
    if "!ACTION_NUM!"=="3" set ACTION=destroy
    if "!ACTION!"=="" (
        echo Invalid selection
        exit /b 1
    )
) else (
    set ACTION=%1
)

set SCRIPT_DIR=%~dp0

if "!ACTION!"=="deploy" (
    set SCRIPT_PATH=!SCRIPT_DIR!windows\deploy.bat
) else if "!ACTION!"=="status" (
    set SCRIPT_PATH=!SCRIPT_DIR!windows\status.bat
) else if "!ACTION!"=="destroy" (
    set SCRIPT_PATH=!SCRIPT_DIR!windows\destroy.bat
) else (
    echo Invalid action: !ACTION!
    echo Valid actions: deploy, status, destroy
    exit /b 1
)

if not exist "!SCRIPT_PATH!" (
    echo Script not found: !SCRIPT_PATH!
    exit /b 1
)

echo Running: !SCRIPT_PATH!
echo.

call "!SCRIPT_PATH!"

endlocal