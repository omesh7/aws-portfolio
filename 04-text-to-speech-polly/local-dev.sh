#!/bin/bash
# Local development script for Project 04

echo "🚀 Project 04 - Local Development Mode"

# Navigate to infrastructure directory
cd infrastructure

echo "Environment: local"
echo "Using terraform.tfvars for configuration"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan

# Ask for confirmation
read -p "Apply changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying changes..."
    terraform apply -auto-approve
    echo "✅ Local deployment complete!"
    
    # Show outputs
    echo "📋 Outputs:"
    terraform output
    
    # Test the function
    LAMBDA_URL=$(terraform output -raw lambda_function_url)
    echo "🧪 Testing Lambda function..."
    curl -X POST "$LAMBDA_URL" \
      -H "Content-Type: application/json" \
      -d '{"text": "Hello from local development!", "voice": "Joanna"}'
else
    echo "❌ Deployment cancelled"
fi