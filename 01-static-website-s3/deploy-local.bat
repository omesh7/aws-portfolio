@echo off
echo ========================================
echo Project 01 - Static Website Local Deploy
echo ========================================

cd /d "%~dp0"

echo.
echo Installing site dependencies...
cd site
call npm install
if %errorlevel% neq 0 (
    echo Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Building site...
call npm run build
if %errorlevel% neq 0 (
    echo Failed to build site
    pause
    exit /b 1
)

echo.
echo Deploying infrastructure...
cd ..\infrastructure

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo Terraform init failed
    pause
    exit /b 1
)

echo Applying Terraform configuration...
terraform apply -var="environment=local" -auto-approve
if %errorlevel% neq 0 (
    echo Terraform apply failed
    pause
    exit /b 1
)

echo.
echo Getting S3 bucket name...
for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name') do set BUCKET_NAME=%%i
echo Bucket: %BUCKET_NAME%

echo.
echo Uploading site files to S3...
cd ..\site\dist
aws s3 sync . s3://%BUCKET_NAME%/ --delete

echo.
echo Invalidating CloudFront...
cd ..\..\infrastructure
for /f "tokens=*" %%i in ('terraform output -raw cloudfront_distribution_id') do set DIST_ID=%%i
aws cloudfront create-invalidation --distribution-id %DIST_ID% --paths "/*"

echo.
echo Deployment completed successfully!
echo.
echo Outputs:
terraform output

pause