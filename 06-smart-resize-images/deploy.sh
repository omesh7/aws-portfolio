#!/bin/bash

# Project 06 - Smart Image Resizer Local Deployment Script

set -e

echo "🚀 Starting local deployment for Project 06 - Smart Image Resizer"

# Check if we're in the right directory
if [ ! -d "06-smart-resize-images" ]; then
    echo "❌ Please run this script from the aws-portfolio root directory"
    exit 1
fi

cd 06-smart-resize-images

# Build Lambda package locally
echo "📦 Building Lambda package..."
cd lambda
npm ci --production --omit=dev
cd ..

# Deploy infrastructure
echo "🏗️ Deploying infrastructure..."
cd infrastructure

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Check if Vercel token is set
if [ -z "$VERCEL_API_TOKEN" ]; then
    echo "⚠️  VERCEL_API_TOKEN not set - deploying AWS only"
    terraform apply -auto-approve \
        -var="environment=local" \
        -var="vercel_api_token="
else
    echo "🚀 Deploying AWS + Vercel..."
    terraform apply -auto-approve \
        -var="environment=local" \
        -var="vercel_api_token=$VERCEL_API_TOKEN"
fi

echo "✅ Deployment completed!"
echo "📋 Outputs:"
terraform output -json | jq '.'