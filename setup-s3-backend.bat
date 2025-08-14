@echo off

echo Setting up S3 backend for Terraform state...

set BUCKET_NAME=aws-portfolio-terraform-state
set TABLE_NAME=aws-portfolio-terraform-locks
set REGION=ap-south-1

echo Testing AWS credentials...
aws sts get-caller-identity
if errorlevel 1 (
    echo AWS credentials not configured properly
    echo Run: aws configure
    pause
    exit /b 1
)

echo Creating S3 bucket: %BUCKET_NAME%
aws s3 mb s3://%BUCKET_NAME% --region %REGION%

echo Enabling versioning...
aws s3api put-bucket-versioning --bucket %BUCKET_NAME% --versioning-configuration Status=Enabled

echo Creating DynamoDB table: %TABLE_NAME%
aws dynamodb create-table --table-name %TABLE_NAME% --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region %REGION%

echo Waiting for table to be ready...
aws dynamodb wait table-exists --table-name %TABLE_NAME% --region %REGION%

echo S3 backend setup complete!
echo Bucket: s3://%BUCKET_NAME%
echo Table: %TABLE_NAME%
echo Region: %REGION%

pause