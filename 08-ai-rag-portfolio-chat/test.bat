@echo off
setlocal enabledelayedexpansion

echo ========================================
echo AWS RAG Portfolio Chat - TESTING
echo ========================================

set AWS_REGION=ap-south-1

echo [1/5] Getting bucket name from Terraform...
cd infrastructure
for /f "tokens=*" %%i in ('terraform output -raw bucket_name 2^>nul') do set BUCKET_NAME=%%i
cd ..

if "%BUCKET_NAME%"=="" (
    echo ERROR: Could not get bucket name from Terraform output
    echo Make sure infrastructure is deployed first
    exit /b 1
)

echo Using bucket: %BUCKET_NAME%

echo [2/5] Creating test documents...
mkdir test-docs 2>nul

echo This is a test document for RAG processing. > test-docs\test.txt
echo It contains sample content about AWS portfolio projects. >> test-docs\test.txt
echo The system should process this and create vector embeddings. >> test-docs\test.txt

echo [2/4] Uploading test file to S3...
aws s3 cp test-docs\test.txt s3://%BUCKET_NAME%/docs/test.txt
if errorlevel 1 (
    echo ERROR: Failed to upload test file
    exit /b 1
)

echo [3/4] Waiting for Lambda processing...
timeout /t 10 /nobreak

echo [4/4] Checking results...
aws s3 ls s3://%BUCKET_NAME%/indices/ --recursive
if errorlevel 1 (
    echo WARNING: No indices found yet, Lambda may still be processing
) else (
    echo SUCCESS: Vector indices created!
)

echo.
echo ========================================
echo MANUAL TESTING OPTIONS:
echo ========================================
echo 1. Check CloudWatch logs:
echo    aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/ai-rag-processor"
echo.
echo 2. Test Lambda function directly:
echo    aws lambda invoke --function-name %BUCKET_NAME%-function --payload "{\"bucket\":\"%BUCKET_NAME%\",\"key\":\"docs/test.txt\"}" response.json
echo.
echo 3. Check S3 bucket contents:
echo    aws s3 ls s3://%BUCKET_NAME%/ --recursive
echo.

pause