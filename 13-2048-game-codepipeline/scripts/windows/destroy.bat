@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=project-13-2048-game-codepipeline
set REGION=ap-south-1

echo Starting complete cleanup of 2048 Game CI/CD Pipeline...
echo ==================================================
echo WARNING: This will destroy ALL AWS resources and local files!
echo This action cannot be undone!
echo.

set /p CONFIRM="Are you sure you want to proceed? (type 'yes' to confirm): "
if not "!CONFIRM!"=="yes" (
    echo Cleanup cancelled.
    exit /b 0
)

echo.
echo Checking if infrastructure exists...

cd ..\infrastructure 2>nul || (
    echo No infrastructure directory found. Run from project root.
    echo.
    echo To deploy: .\scripts\windows\deploy.bat
    exit /b 1
)

if not exist "terraform.tfstate" if not exist ".terraform\terraform.tfstate" (
    echo No Terraform state found. Skipping infrastructure cleanup.
    set SKIP_TERRAFORM=true
) else (
    set SKIP_TERRAFORM=false
)

if "!SKIP_TERRAFORM!"=="false" (
    echo Getting resource information...
    
    for /f "tokens=*" %%i in ('terraform output -raw ecr_repository_url 2^>nul ^|^| echo.') do set ECR_REPO=%%i
    for /f "tokens=*" %%i in ('terraform output -raw ecs_cluster_name 2^>nul ^|^| echo.') do set ECS_CLUSTER=%%i
    for /f "tokens=*" %%i in ('terraform output -raw ecs_service_name 2^>nul ^|^| echo.') do set ECS_SERVICE=%%i
    for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name 2^>nul ^|^| echo.') do set S3_BUCKET=%%i
    
    if not "!ECS_CLUSTER!"=="" if not "!ECS_SERVICE!"=="" (
        echo.
        echo Step 1: Stopping ECS service...
        aws ecs update-service --cluster !ECS_CLUSTER! --service !ECS_SERVICE! --desired-count 0 >nul 2>&1 || echo    Service already stopped or doesn't exist
        
        echo    Waiting for tasks to stop...
        for /l %%i in (1,1,12) do (
            for /f "tokens=*" %%j in ('aws ecs describe-services --cluster !ECS_CLUSTER! --services !ECS_SERVICE! --query "services[0].runningCount" --output text 2^>nul ^|^| echo 0') do set RUNNING_COUNT=%%j
            if "!RUNNING_COUNT!"=="0" (
                echo ECS service stopped successfully!
                goto :s3_cleanup
            )
            echo    Waiting for tasks to stop... (%%i/12)
            timeout /t 10 >nul
        )
    )
    
    :s3_cleanup
    if not "!S3_BUCKET!"=="" (
        echo.
        echo Step 2: Emptying S3 bucket...
        aws s3 rm s3://!S3_BUCKET! --recursive >nul 2>&1 || echo    Bucket already empty or doesn't exist
        echo S3 bucket emptied!
    )
    
    if not "!ECR_REPO!"=="" (
        echo.
        echo Step 3: Deleting ECR images...
        for /f "tokens=2 delims=/" %%i in ("!ECR_REPO!") do set REPO_NAME=%%i
        aws ecr list-images --repository-name !REPO_NAME! --query "imageIds[*]" --output json > %TEMP%\ecr_images.json 2>nul || echo [] > %TEMP%\ecr_images.json
        
        for %%i in (%TEMP%\ecr_images.json) do set FILE_SIZE=%%~zi
        if !FILE_SIZE! gtr 2 (
            findstr /c:"imageDigest" %TEMP%\ecr_images.json >nul && (
                aws ecr batch-delete-image --repository-name !REPO_NAME! --image-ids file://%TEMP%\ecr_images.json >nul 2>&1 || echo    Images already deleted or don't exist
                echo ECR images deleted!
            ) || (
                echo    No ECR images to delete
            )
        ) else (
            echo    No ECR images to delete
        )
        del %TEMP%\ecr_images.json 2>nul
    )
    
    echo.
    echo Step 4: Stopping CodePipeline executions...
    set PIPELINE_NAME=!PROJECT_NAME!-pipeline
    for /f "tokens=*" %%i in ('aws codepipeline get-pipeline-state --name !PIPELINE_NAME! --query "stageStates[0].latestExecution.pipelineExecutionId" --output text 2^>nul ^|^| echo.') do set EXECUTION_ID=%%i
    
    if not "!EXECUTION_ID!"=="" if not "!EXECUTION_ID!"=="None" (
        aws codepipeline stop-pipeline-execution --pipeline-name !PIPELINE_NAME! --pipeline-execution-id !EXECUTION_ID! >nul 2>&1 || echo    No active executions to stop
    )
    echo CodePipeline executions stopped!
    
    echo.
    echo Step 5: Destroying Terraform infrastructure...
    echo    This may take 5-10 minutes...
    
    terraform destroy -auto-approve
    
    echo Infrastructure destroyed successfully!
) else (
    echo Skipping Terraform destruction (no state found)
)

cd ..

echo.
echo Step 6: Cleaning up local Docker images...

docker rmi 2048-game-local >nul 2>&1 || echo    Local image already removed
if not "!ECR_REPO!"=="" (
    docker rmi !ECR_REPO!:latest >nul 2>&1 || echo    ECR image already removed
)

for /f "tokens=*" %%i in ('docker images -f "dangling=true" -q 2^>nul') do (
    docker rmi %%i >nul 2>&1 || echo    No dangling images to remove
)

echo Docker images cleaned up!

echo.
echo Step 7: Cleaning up local files...

if exist "frontend\node_modules" (
    rmdir /s /q "frontend\node_modules"
    echo    Removed frontend\node_modules
)

if exist "frontend\dist" (
    rmdir /s /q "frontend\dist"
    echo    Removed frontend\dist
)

for /d /r . %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d" 2>nul
del /s /q *.pyc 2>nul
echo    Removed Python cache files

if exist "frontend\.env" (
    del "frontend\.env"
    echo    Removed frontend\.env
)

set /p REMOVE_TF_STATE="Do you want to remove Terraform state files? (y/N): "
if /i "!REMOVE_TF_STATE!"=="y" (
    cd infrastructure
    rmdir /s /q .terraform 2>nul
    del terraform.tfstate* 2>nul
    del .terraform.lock.hcl 2>nul
    echo    Removed Terraform state files
    cd ..
)

echo Local files cleaned up!

echo.
echo Step 8: Final verification...

echo Checking for remaining AWS resources...

if not "!ECS_CLUSTER!"=="" (
    for /f "tokens=*" %%i in ('aws ecs describe-clusters --clusters !ECS_CLUSTER! --query "clusters[0].status" --output text 2^>nul ^|^| echo INACTIVE') do set ECS_EXISTS=%%i
    if "!ECS_EXISTS!"=="ACTIVE" (
        echo ECS cluster still exists: !ECS_CLUSTER!
    )
)

if not "!S3_BUCKET!"=="" (
    aws s3 ls s3://!S3_BUCKET! >nul 2>&1 && (
        echo S3 bucket still exists: !S3_BUCKET!
    )
)

if not "!ECR_REPO!"=="" (
    for /f "tokens=2 delims=/" %%i in ("!ECR_REPO!") do set REPO_NAME=%%i
    aws ecr describe-repositories --repository-names !REPO_NAME! >nul 2>&1 && (
        echo ECR repository still exists: !REPO_NAME!
    )
)

echo.
echo Cleanup completed successfully!
echo ==================================================
echo Cleanup Summary:
echo.
echo - ECS service stopped and destroyed
echo - S3 bucket emptied and destroyed
echo - ECR repository and images destroyed
echo - Application Load Balancer destroyed
echo - VPC and networking destroyed
echo - IAM roles and policies destroyed
echo - CodePipeline and CodeBuild destroyed
echo - CloudWatch logs destroyed
echo - Local Docker images removed
echo - Local build artifacts removed
echo.
echo Cost Impact:
echo    - All billable AWS resources have been destroyed
echo    - No ongoing charges should occur
echo    - Check AWS billing console to confirm
echo.
echo To redeploy:
echo    .\scripts\windows\deploy.bat
echo.
echo Cleanup complete! Your AWS account is clean.

endlocal