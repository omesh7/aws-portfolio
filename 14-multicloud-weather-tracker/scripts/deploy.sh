#!/bin/bash

# Multi-Cloud Weather Tracker Deployment Script

set -e

echo "🌤️  Multi-Cloud Weather Tracker Deployment"
echo "=========================================="

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed."; exit 1; }
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI is required but not installed."; exit 1; }

# Check if domain name is provided
if [ -z "$1" ]; then
    echo "❌ Please provide a domain name as the first argument"
    echo "Usage: ./deploy.sh your-domain.com"
    exit 1
fi

DOMAIN_NAME=$1
echo "🌐 Domain: $DOMAIN_NAME"

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -var="domain_name=$DOMAIN_NAME"

# Apply infrastructure
echo "🚀 Deploying infrastructure..."
terraform apply -var="domain_name=$DOMAIN_NAME" -auto-approve

# Get outputs
AWS_BUCKET=$(terraform output -raw aws_s3_bucket)
AZURE_STORAGE=$(terraform output -raw azure_storage_account)

echo "📦 Deploying frontend to AWS S3..."
aws s3 sync ../frontend/ s3://$AWS_BUCKET/ --delete

echo "📦 Deploying frontend to Azure Blob Storage..."
az storage blob upload-batch \
    --account-name $AZURE_STORAGE \
    --destination '$web' \
    --source ../frontend/

echo "✅ Deployment completed successfully!"
echo ""
echo "🔗 Endpoints:"
echo "   AWS Primary: $(terraform output -raw aws_cloudfront_domain)"
echo "   Azure Secondary: $(terraform output -raw azure_cdn_endpoint)"
echo ""
echo "📋 Next steps:"
echo "   1. Update your domain's nameservers to:"
terraform output route53_nameservers
echo "   2. Wait for DNS propagation (5-10 minutes)"
echo "   3. Test failover by accessing your domain"