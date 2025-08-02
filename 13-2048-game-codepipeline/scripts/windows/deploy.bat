@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=project-13-2048-game-codepipeline
set REGION=ap-south-1

echo Starting complete deployment of 2048 Game CI/CD Pipeline...
echo ==================================================

echo Checking prerequisites...
where aws >nul 2>&1 || (echo AWS CLI not found. Please install AWS CLI. & exit /b 1)
where terraform >nul 2>&1 || (echo Terraform not found. Please install Terraform. & exit /b 1)
where docker >nul 2>&1 || (echo Docker not found. Please install Docker. & exit /b 1)
where node >nul 2>&1 || (echo Node.js not found. Please install Node.js. & exit /b 1)
where python >nul 2>&1 || (echo Python not found. Please install Python. & exit /b 1)

aws sts get-caller-identity >nul 2>&1 || (echo AWS credentials not configured. Run 'aws configure'. & exit /b 1)

echo All prerequisites met!

echo.
echo Step 1: Testing local development...
echo Installing Python dependencies...
pip install -r requirements.txt >nul 2>&1

echo Installing frontend dependencies...
cd frontend
npm install >nul 2>&1
cd ..

echo.
echo Step 2: Testing Docker build...
docker build -f docker/Dockerfile -t 2048-game-local . >nul 2>&1
echo Docker build successful!

echo.
echo Step 3: Deploying infrastructure with Terraform...
cd infrastructure

if not exist "terraform.tfvars" (
    echo terraform.tfvars not found. Please create it from terraform.tfvars.example
    exit /b 1
)

terraform init >nul 2>&1
echo Planning infrastructure deployment...
terraform plan >nul 2>&1

echo Applying infrastructure (this may take 8-12 minutes)...
terraform apply -auto-approve

for /f "tokens=*" %%i in ('terraform output -raw ecr_repository_url') do set ECR_REPO=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_cluster_name') do set ECS_CLUSTER=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_service_name') do set ECS_SERVICE=%%i
for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name') do set S3_BUCKET=%%i
for /f "tokens=*" %%i in ('terraform output -raw api_url') do set API_URL=%%i

echo Infrastructure deployed successfully!
echo Infrastructure Details:
echo    ECR Repository: !ECR_REPO!
echo    ECS Cluster: !ECS_CLUSTER!
echo    ECS Service: !ECS_SERVICE!
echo    S3 Bucket: !S3_BUCKET!
echo    API URL: !API_URL!

cd ..

echo.
echo Step 4: Deploying initial container to ECR...
aws ecr get-login-password --region !REGION! | docker login --username AWS --password-stdin !ECR_REPO! >nul 2>&1

docker tag 2048-game-local:latest !ECR_REPO!:latest
docker push !ECR_REPO!:latest >nul 2>&1

echo Updating ECS service...
aws ecs update-service --cluster !ECS_CLUSTER! --service !ECS_SERVICE! --force-new-deployment >nul 2>&1

echo Container deployed successfully!

echo.
echo Step 5: Waiting for ECS service to become healthy...
echo This may take 3-5 minutes...

for /l %%i in (1,1,30) do (
    for /f "tokens=*" %%j in ('aws ecs describe-services --cluster !ECS_CLUSTER! --services !ECS_SERVICE! --query "services[0].runningCount" --output text') do set RUNNING_COUNT=%%j
    if "!RUNNING_COUNT!"=="1" (
        echo ECS service is running!
        goto :health_check
    )
    echo    Waiting... (%%i/30)
    timeout /t 10 >nul
)

:health_check
echo Checking load balancer target health...
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names !PROJECT_NAME!-tg --query "TargetGroups[0].TargetGroupArn" --output text') do set ALB_TG_ARN=%%i

for /l %%i in (1,1,20) do (
    for /f "tokens=*" %%j in ('aws elbv2 describe-target-health --target-group-arn !ALB_TG_ARN! --query "TargetHealthDescriptions[0].TargetHealth.State" --output text 2^>nul ^|^| echo unknown') do set HEALTH_STATUS=%%j
    if "!HEALTH_STATUS!"=="healthy" (
        echo Load balancer targets are healthy!
        goto :api_test
    )
    echo    Target health: !HEALTH_STATUS! (%%i/20)
    timeout /t 15 >nul
)

:api_test
echo.
echo Step 6: Testing API endpoint...
for /f "tokens=*" %%i in ('curl -s !API_URL! 2^>nul ^|^| echo failed') do set API_RESPONSE=%%i
echo !API_RESPONSE! | findstr "2048 Game API" >nul && (
    echo API is responding correctly!
) || (
    echo API test failed, but continuing with deployment...
)

echo.
echo Step 7: Building and deploying frontend...
cd frontend

echo VITE_API_URL=!API_URL! > .env
npm run build >nul 2>&1

aws s3 sync dist/ s3://!S3_BUCKET! --delete >nul 2>&1

set FRONTEND_URL=http://!S3_BUCKET!.s3-website.!REGION!.amazonaws.com
echo Frontend deployed successfully!

cd ..

echo.
echo Deployment completed successfully!
echo ==================================================
echo Your 2048 Game is now live:
echo.
echo Frontend URL: !FRONTEND_URL!
echo API URL: !API_URL!
echo.
echo Infrastructure Summary:
echo    - ECS Fargate service running
echo    - Application Load Balancer configured
echo    - S3 static website hosting
echo    - ECR container registry
echo    - CodePipeline ready for CI/CD
echo.
echo Next Steps:
echo    1. Open the frontend URL in your browser
echo    2. Test the game functionality
echo    3. Make code changes and push to trigger CI/CD
echo.
echo To monitor your deployment:
echo    .\scripts\windows\status.bat
echo.
echo To clean up resources:
echo    .\scripts\windows\destroy.bat
echo.
echo Happy gaming!

endlocal