#!/bin/bash

set -e

echo "==========================================="
echo "🌤️  Multi-Cloud Weather Tracker Deployment"
echo "==========================================="
echo

# Get absolute path to project root (works from any directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
if [ ! -d "$PROJECT_ROOT/infrastructure" ]; then
    PROJECT_ROOT="$SCRIPT_DIR/../../14-multicloud-weather-tracker"
fi
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ Error: Cannot find project root directory"
    echo "Current script location: $SCRIPT_DIR"
    exit 1
fi

echo "📁 Project root: $PROJECT_ROOT"
echo

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v terraform >/dev/null 2>&1; then
    echo "❌ [ERROR] Terraform is required but not found in PATH"
    echo "Please install Terraform: https://terraform.io/downloads"
    exit 1
fi
echo "✅ [OK] Terraform found"

if ! command -v aws >/dev/null 2>&1; then
    echo "❌ [ERROR] AWS CLI is required but not found in PATH"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi
echo "✅ [OK] AWS CLI found"

# Check AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ [ERROR] AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi
echo "✅ [OK] AWS credentials configured"

echo

# Navigate to infrastructure directory
INFRA_DIR="$PROJECT_ROOT/infrastructure"
if [ ! -d "$INFRA_DIR" ]; then
    echo "❌ [ERROR] Infrastructure directory not found: $INFRA_DIR"
    exit 1
fi

cd "$INFRA_DIR"
echo "📂 Working directory: $(pwd)"
echo

# Check for terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  [WARNING] terraform.tfvars not found"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    if [ -f "terraform.tfvars.example" ]; then
        echo "Example file found at: $INFRA_DIR/terraform.tfvars.example"
    fi
    exit 1
fi

echo "🔧 [1/4] Initializing Terraform..."
if ! terraform init; then
    echo "❌ [ERROR] Terraform initialization failed"
    exit 1
fi
echo

echo "📋 [2/4] Planning deployment..."
if ! terraform plan; then
    echo "❌ [ERROR] Terraform plan failed"
    exit 1
fi
echo

echo "🚀 [3/4] Deploying infrastructure..."
echo
echo "Multi-Cloud Deployment Options:"
echo "  - AWS + GCP (Parallel): Both clouds deploy simultaneously"
echo "  - AWS Only: Deploy only AWS infrastructure"
echo "  - Current config: Both AWS and GCP are enabled"
echo
echo "Note: GCP APIs will be enabled automatically (may take 2-3 minutes)"
echo
if ! terraform apply -auto-approve; then
    echo "❌ [ERROR] Terraform apply failed"
    echo
    echo "Troubleshooting:"
    echo "- GCP APIs may need time to propagate (wait 2-3 minutes and retry)"
    echo "- Check GCP credentials: gcloud auth application-default login"
    echo "- Verify gcp_project_id in terraform.tfvars"
    echo "- Enable billing on GCP project if not already enabled"
    exit 1
fi
echo

echo "📦 [4/4] Deploying frontend..."
# Get outputs from Terraform
AWS_BUCKET=$(terraform output -raw aws_s3_bucket 2>/dev/null || echo "")
LAMBDA_URL=$(terraform output -raw aws_lambda_function_url_weather_tracker_url 2>/dev/null || echo "")

if [ -z "$AWS_BUCKET" ]; then
    echo "❌ [ERROR] Could not get S3 bucket name from Terraform output"
    exit 1
fi

if [ -z "$LAMBDA_URL" ]; then
    echo "❌ [ERROR] Could not get Lambda URL from Terraform output"
    exit 1
fi

echo "🪣 S3 Bucket: $AWS_BUCKET"
echo "🔗 Lambda URL: $LAMBDA_URL"
echo

# Prepare frontend files
FRONTEND_DIR="$PROJECT_ROOT/frontend"
TEMP_DIR="$PROJECT_ROOT/temp-frontend"

if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ [ERROR] Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

echo "🔧 Preparing frontend files..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cp -r "$FRONTEND_DIR/"* "$TEMP_DIR/"

# Update API configuration
echo "window.LAMBDA_API_URL = '${LAMBDA_URL}api/weather';" > "$TEMP_DIR/config.js"

# Deploy to S3
echo "☁️  Uploading to S3..."
if ! aws s3 sync "$TEMP_DIR/" s3://$AWS_BUCKET/ --delete; then
    echo "❌ [ERROR] S3 sync failed"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo
echo "==========================================="
echo "✅ Deployment completed successfully!"
echo "==========================================="
WEATHER_URL=$(terraform output -raw weather_app_url 2>/dev/null || echo "")
if [ -n "$WEATHER_URL" ]; then
    echo
    echo "🔗 Application URL: $WEATHER_URL"
    echo
fi