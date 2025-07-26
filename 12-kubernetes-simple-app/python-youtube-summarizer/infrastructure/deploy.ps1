# Terraform Deployment Script

param(
    [Parameter(Mandatory = $false)]
    [string]$Action = "apply",
    
    [Parameter(Mandatory = $false)]
    [string]$VarFile = "secrets.auto.tfvars"
)

Write-Host "Running Terraform $Action..." -ForegroundColor Green

# Check if secrets.auto.tfvars exists
if (-not (Test-Path $VarFile)) {
    Write-Host "Error: $VarFile not found!" -ForegroundColor Red
    Write-Host "Please copy secrets.auto.tfvars.example to secrets.auto.tfvars and fill in your API keys" -ForegroundColor Yellow
    exit 1
}

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($Action -eq "plan") {
    # Plan
    Write-Host "Running Terraform plan..." -ForegroundColor Yellow
    terraform plan -var-file="$VarFile"
}
elseif ($Action -eq "apply") {
    # Apply
    Write-Host "Running Terraform apply..." -ForegroundColor Yellow
    terraform apply -var-file="$VarFile" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment successful!" -ForegroundColor Green
        Write-Host "Getting outputs..." -ForegroundColor Yellow
        terraform output
    }
}
elseif ($Action -eq "destroy") {
    # Destroy
    Write-Host "Running Terraform destroy..." -ForegroundColor Red
    terraform destroy -var-file="$VarFile" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Resources destroyed successfully!" -ForegroundColor Green
    }
}
else {
    Write-Host "Invalid action. Use: plan, apply, or destroy" -ForegroundColor Red
    exit 1
}