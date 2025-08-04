#!/bin/bash

set -e

echo "🌤️  Multi-Cloud Weather Tracker Deployment"
echo "=========================================="

command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI required"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../terraform"

echo "🔧 Initializing Terraform..."
terraform init

echo "🚀 Deploying infrastructure..."
terraform apply -auto-approve

AWS_BUCKET=$(terraform output -raw aws_s3_bucket)
LAMBDA_URL=$(terraform output -raw aws_lambda_function_url_weather_tracker_url)

echo "🔧 Updating API configuration..."
PROJ_DIR="$SCRIPT_DIR/../.."
mkdir -p "$PROJ_DIR/temp-frontend"
cp -r "$PROJ_DIR/frontend/"* "$PROJ_DIR/temp-frontend/"
echo "window.LAMBDA_API_URL = '${LAMBDA_URL}api/weather';" > "$PROJ_DIR/temp-frontend/api-config.js"

echo "📦 Deploying frontend..."
aws s3 sync "$PROJ_DIR/temp-frontend/" s3://$AWS_BUCKET/ --delete
rm -rf "$PROJ_DIR/temp-frontend"

echo "✅ Deployment completed!"
echo "🔗 URL: $(terraform output -raw weather_app_url)"