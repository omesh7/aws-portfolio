# Import existing AWS resources into Terraform state

Write-Host "Importing existing AWS resources..." -ForegroundColor Yellow

# Import CloudWatch Log Group
Write-Host "Importing CloudWatch Log Group..." -ForegroundColor Cyan
terraform import aws_cloudwatch_log_group.app "/ecs/youtube-summarizer"

# Import ECS Cluster
Write-Host "Importing ECS Cluster..." -ForegroundColor Cyan
terraform import aws_ecs_cluster.main "youtube-summarizer-cluster"

Write-Host "Import complete! Now run terraform apply again." -ForegroundColor Green