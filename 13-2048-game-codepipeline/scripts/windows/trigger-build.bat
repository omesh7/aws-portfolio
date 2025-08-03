@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=proj-13-2048-game-cp

echo Manually triggering CodePipeline build...
echo ==========================================

cd /d "%~dp0..\.."
cd infrastructure 2>nul || (
    echo No infrastructure directory found.
    exit /b 1
)

if not exist "terraform.tfstate" if not exist ".terraform\terraform.tfstate" (
    echo No Terraform state found. Infrastructure not deployed.
    exit /b 1
)

for /f "tokens=*" %%i in ('terraform output -raw codepipeline_name 2^>nul ^|^| echo') do set PIPELINE_NAME=%%i

if "!PIPELINE_NAME!"=="" (
    echo Pipeline name not found in Terraform outputs.
    exit /b 1
)

echo Pipeline: !PIPELINE_NAME!
echo Triggering build...

aws codepipeline start-pipeline-execution --name !PIPELINE_NAME!
if errorlevel 1 (
    echo Failed to trigger pipeline
    exit /b 1
)

echo Build triggered successfully!
echo.
echo Monitor progress:
echo   AWS Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/!PIPELINE_NAME!/view
echo   Status script: .\scripts\windows\status.bat

endlocal