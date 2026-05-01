# Build and Push Docker Image Script

param(
    [Parameter(Mandatory=$true)]
    [string]$AccountId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "ap-south-1",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest"
)

$ECR_URI = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$REPO_NAME = "youtube-summarizer"

Write-Host "Building and pushing Docker image..." -ForegroundColor Green

# Navigate to docker directory
Set-Location -Path "../docker"

# Build image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t $REPO_NAME`:$ImageTag .

# Get ECR login
Write-Host "Logging into ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $ECR_URI

# Tag for ECR
Write-Host "Tagging image for ECR..." -ForegroundColor Yellow
docker tag $REPO_NAME`:$ImageTag $ECR_URI/$REPO_NAME`:$ImageTag

# Push to ECR
Write-Host "Pushing image to ECR..." -ForegroundColor Yellow
docker push $ECR_URI/$REPO_NAME`:$ImageTag

Write-Host "Image pushed successfully: $ECR_URI/$REPO_NAME`:$ImageTag" -ForegroundColor Green