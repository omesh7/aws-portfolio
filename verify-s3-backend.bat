@echo off
REM Verify S3 backend setup

echo 🔍 Verifying S3 backend setup...

set BUCKET_NAME=aws-portfolio-terraform-state
set TABLE_NAME=aws-portfolio-terraform-locks
set REGION=ap-south-1

echo Checking S3 bucket...
aws s3 ls s3://%BUCKET_NAME% --region %REGION%

echo.
echo Checking DynamoDB table...
aws dynamodb describe-table --table-name %TABLE_NAME% --region %REGION% --query "Table.TableStatus"

echo.
echo Checking bucket versioning...
aws s3api get-bucket-versioning --bucket %BUCKET_NAME%

echo.
echo ✅ Verification complete!

pause