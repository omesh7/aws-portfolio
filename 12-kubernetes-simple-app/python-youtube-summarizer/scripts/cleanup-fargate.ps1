# AWS Fargate Cleanup Script

param(
    [Parameter(Mandatory=$true)]
    [string]$AccountId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "ap-south-1"
)

$ECR_URI = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$REPO_NAME = "youtube-summarizer"

Write-Host "Cleaning up AWS Fargate resources..." -ForegroundColor Yellow

# Stop and delete ECS service
Write-Host "Stopping ECS service..." -ForegroundColor Red
aws ecs update-service --cluster youtube-summarizer-cluster --service youtube-summarizer-service --desired-count 0 --region $Region

Write-Host "Waiting for service to stop..." -ForegroundColor Yellow
aws ecs wait services-stable --cluster youtube-summarizer-cluster --services youtube-summarizer-service --region $Region

Write-Host "Deleting ECS service..." -ForegroundColor Red
aws ecs delete-service --cluster youtube-summarizer-cluster --service youtube-summarizer-service --region $Region

# Delete task definition
Write-Host "Deregistering task definitions..." -ForegroundColor Red
$taskDefs = aws ecs list-task-definitions --family-prefix youtube-summarizer --region $Region --query 'taskDefinitionArns' --output text
if ($taskDefs) {
    $taskDefs.Split() | ForEach-Object {
        aws ecs deregister-task-definition --task-definition $_ --region $Region
    }
}

# Delete ECS cluster
Write-Host "Deleting ECS cluster..." -ForegroundColor Red
aws ecs delete-cluster --cluster youtube-summarizer-cluster --region $Region

# Delete CloudWatch log group
Write-Host "Deleting CloudWatch log group..." -ForegroundColor Red
aws logs delete-log-group --log-group-name "/ecs/youtube-summarizer" --region $Region

# Delete ECR repository
Write-Host "Deleting ECR repository..." -ForegroundColor Red
aws ecr delete-repository --repository-name $REPO_NAME --region $Region --force

# Delete Parameter Store parameters
Write-Host "Deleting Parameter Store parameters..." -ForegroundColor Red
aws ssm delete-parameter --name "/youtube-summarizer/gemini-api-key" --region $Region 2>$null
aws ssm delete-parameter --name "/youtube-summarizer/groq-api-key" --region $Region 2>$null
aws ssm delete-parameter --name "/youtube-summarizer/openai-api-key" --region $Region 2>$null

# Clean up local Docker images
$cleanup = Read-Host "Do you want to clean up local Docker images? (y/N)"
if ($cleanup -eq "y" -or $cleanup -eq "Y") {
    Write-Host "Cleaning up local Docker images..." -ForegroundColor Red
    docker rmi $REPO_NAME`:latest -f 2>$null
    docker rmi $ECR_URI/$REPO_NAME`:latest -f 2>$null
    docker image prune -f
}

Write-Host "Fargate cleanup complete!" -ForegroundColor Green