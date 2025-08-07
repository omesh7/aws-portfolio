@echo off
echo ========================================
echo MANUAL LAMBDA TEST
echo ========================================

set FUNCTION_NAME=08-rag-portfolio-chat-aws-portfolio-function
set BUCKET_NAME=08-rag-portfolio-chat-aws-portfolio

echo Testing Lambda function directly...
aws lambda invoke ^
  --function-name %FUNCTION_NAME% ^
  --payload "{\"bucket\":\"%BUCKET_NAME%\",\"key\":\"docs/sample.txt\"}" ^
  response.json

echo.
echo Response:
type response.json

echo.
echo Checking S3 for generated indices...
aws s3 ls s3://%BUCKET_NAME%/indices/ --recursive

pause