# Clean up existing AWS resources manually

Write-Host "Cleaning up existing AWS resources..." -ForegroundColor Yellow

# Delete ECS Cluster
Write-Host "Deleting ECS Cluster..." -ForegroundColor Red
aws ecs delete-cluster --cluster youtube-summarizer-cluster --region ap-south-1

# Delete CloudWatch Log Group
Write-Host "Deleting CloudWatch Log Group..." -ForegroundColor Red
aws logs delete-log-group --log-group-name "/ecs/youtube-summarizer" --region ap-south-1

# Delete ECR Repository if exists
Write-Host "Deleting ECR Repository..." -ForegroundColor Red
aws ecr delete-repository --repository-name youtube-summarizer --region ap-south-1 --force

Write-Host "Cleanup complete! Now run terraform apply again." -ForegroundColor Green