@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=project-13-2048-game-codepipeline
set REGION=ap-south-1

echo 2048 Game CI/CD Pipeline - Status Check
echo ==================================================

cd ..\infrastructure 2>nul || (
    echo No infrastructure directory found. Run from project root.
    echo.
    echo To deploy: .\scripts\windows\deploy.bat
    exit /b 1
)

if not exist "terraform.tfstate" if not exist ".terraform\terraform.tfstate" (
    echo No Terraform state found. Infrastructure not deployed.
    echo.
    echo To deploy: .\scripts\windows\deploy.bat
    exit /b 1
)

echo Getting resource information...
for /f "tokens=*" %%i in ('terraform output -raw ecr_repository_url 2^>nul ^|^| echo.') do set ECR_REPO=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_cluster_name 2^>nul ^|^| echo.') do set ECS_CLUSTER=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecs_service_name 2^>nul ^|^| echo.') do set ECS_SERVICE=%%i
for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name 2^>nul ^|^| echo.') do set S3_BUCKET=%%i
for /f "tokens=*" %%i in ('terraform output -raw api_url 2^>nul ^|^| echo.') do set API_URL=%%i

cd ..

echo.
echo Infrastructure Status:
echo    ECR Repository: !ECR_REPO!
echo    ECS Cluster: !ECS_CLUSTER!
echo    ECS Service: !ECS_SERVICE!
echo    S3 Bucket: !S3_BUCKET!
echo    API URL: !API_URL!

echo.
echo ECS Service Status:
if not "!ECS_CLUSTER!"=="" if not "!ECS_SERVICE!"=="" (
    aws ecs describe-services --cluster !ECS_CLUSTER! --services !ECS_SERVICE! --query "services[0].{status:status,running:runningCount,desired:desiredCount}" --output table 2>nul || echo Service not found
) else (
    echo ECS service information not available
)

echo.
echo Load Balancer Target Health:
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names !PROJECT_NAME!-tg --query "TargetGroups[0].TargetGroupArn" --output text 2^>nul ^|^| echo.') do set ALB_TG_ARN=%%i
if not "!ALB_TG_ARN!"=="" if not "!ALB_TG_ARN!"=="None" (
    aws elbv2 describe-target-health --target-group-arn !ALB_TG_ARN! --query "TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State}" --output table 2>nul || echo No targets found
) else (
    echo Load balancer target group not found
)

echo.
echo API Health Check:
if not "!API_URL!"=="" (
    for /f "tokens=*" %%i in ('curl -s --max-time 10 !API_URL! 2^>nul ^|^| echo failed') do set API_RESPONSE=%%i
    echo !API_RESPONSE! | findstr "2048 Game API" >nul && (
        echo API is healthy and responding
        echo    Response: !API_RESPONSE!
    ) || (
        echo API is not responding correctly
        echo    Response: !API_RESPONSE!
    )
) else (
    echo API URL not available
)

echo.
echo Frontend Status:
if not "!S3_BUCKET!"=="" (
    set FRONTEND_URL=http://!S3_BUCKET!.s3-website.!REGION!.amazonaws.com
    echo    Frontend URL: !FRONTEND_URL!
    
    for /f %%i in ('aws s3 ls s3://!S3_BUCKET! --recursive ^| find /c /v ""') do set FILE_COUNT=%%i
    if !FILE_COUNT! gtr 0 (
        echo Frontend deployed (!FILE_COUNT! files in S3)
    ) else (
        echo Frontend bucket is empty
    )
) else (
    echo S3 bucket information not available
)

echo.
echo CodePipeline Status:
set PIPELINE_NAME=!PROJECT_NAME!-pipeline
aws codepipeline get-pipeline-state --name !PIPELINE_NAME! --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" --output table 2>nul || echo Pipeline not found

echo.
echo Recent CodeBuild Executions:
set BUILD_PROJECT=!PROJECT_NAME!-build
aws codebuild list-builds-for-project --project-name !BUILD_PROJECT! --sort-order DESCENDING --max-items 3 --query "ids" --output table 2>nul || echo No builds found

echo.
echo Estimated Monthly Costs:
echo    ECS Fargate (256 CPU, 512MB): ~$15-20
echo    Application Load Balancer: ~$16
echo    S3 Storage (1GB): ~$0.02
echo    ECR Storage (1GB): ~$0.10
echo    CodePipeline: ~$1
echo    Data Transfer: ~$1-5
echo    --------------------------------
echo    Total Estimated: ~$33-42/month

echo.
echo Quick Actions:
echo    View logs: aws logs tail "/ecs/!PROJECT_NAME!" --follow
echo    Force deployment: aws ecs update-service --cluster !ECS_CLUSTER! --service !ECS_SERVICE! --force-new-deployment
echo    Trigger pipeline: aws codepipeline start-pipeline-execution --name !PIPELINE_NAME!
echo.
echo Monitoring:
echo    ECS Console: https://console.aws.amazon.com/ecs/home?region=!REGION!#/clusters/!ECS_CLUSTER!/services
echo    Pipeline Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/!PIPELINE_NAME!/view
echo.
echo Cleanup:
echo    .\scripts\windows\destroy.bat

endlocal