#!/bin/bash

echo "========================================"
echo "Project 01 - Static Website Local Deploy"
echo "========================================"

cd "$(dirname "$0")"

echo ""
echo "📦 Installing site dependencies..."
cd site
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "🏗️ Building site..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Failed to build site"
    exit 1
fi

echo ""
echo "🚀 Deploying infrastructure..."
cd ../infrastructure

echo "Initializing Terraform..."
terraform init
if [ $? -ne 0 ]; then
    echo "❌ Terraform init failed"
    exit 1
fi

echo "Applying Terraform configuration..."
terraform apply -var="environment=local" -var="upload_site_files=true"
if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed"
    exit 1
fi

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Outputs:"
terraform output