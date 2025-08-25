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
terraform apply -var="environment=local" -auto-approve
if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed"
    exit 1
fi

echo ""
echo "📦 Getting S3 bucket name..."
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "Bucket: $BUCKET_NAME"

echo ""
echo "🚀 Uploading site files to S3..."
cd ../site/dist
aws s3 sync . s3://$BUCKET_NAME/ --delete

echo ""
echo "🔄 Invalidating CloudFront..."
cd ../../infrastructure
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Outputs:"
terraform output