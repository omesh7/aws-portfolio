@echo off
REM Local development script for Project 04 (Windows)

echo Project 04 - Local Development Mode

REM Navigate to infrastructure directory
cd infrastructure

echo Environment: local
echo Using terraform.tfvars for configuration

REM Initialize Terraform
echo Initializing Terraform...
terraform init

REM Plan deployment
echo Planning deployment...
terraform plan

REM Ask for confirmation
set /p REPLY="Apply changes? (y/N): "
if /i "%REPLY%"=="y" (
    echo Applying changes...
    terraform apply -auto-approve
    echo Local deployment complete!
    
    REM Show outputs
    echo Outputs:
    terraform output
    
    REM Test the function
    echo Testing Lambda function...
    for /f "tokens=*" %%i in ('terraform output -raw lambda_function_url') do set LAMBDA_URL=%%i
    curl -X POST "%LAMBDA_URL%" -H "Content-Type: application/json" -d "{\"text\": \"Hello from local development!\", \"voice\": \"Joanna\"}"
) else (
    echo Deployment cancelled
)

pause