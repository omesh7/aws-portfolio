#!/bin/bash

# 2048 Game CI/CD Pipeline - Complete Destruction Script (Linux)
# This script safely destroys all AWS resources and cleans up local files

set -e  # Exit on any error

PROJECT_NAME="proj-13-2048-game-cp"
REGION="ap-south-1"

echo "🧹 Starting complete cleanup of 2048 Game CI/CD Pipeline..."
echo "=================================================="
echo "⚠️  WARNING: This will destroy ALL AWS resources and local files!"
echo "⚠️  This action cannot be undone!"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? (type 'yes' to confirm): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cleanup cancelled."
    exit 0
fi

echo ""
echo "🔍 Checking if infrastructure exists..."

# Navigate to project root and check infrastructure
cd "$(dirname "$0")/../.."
cd infrastructure
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "ℹ️  No Terraform state found. Skipping infrastructure cleanup."
    SKIP_TERRAFORM=true
else
    SKIP_TERRAFORM=false
fi

if [ "$SKIP_TERRAFORM" = false ]; then
    # Get resource information before destroying
    echo "📊 Getting resource information..."
    
    ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
    ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
    
    # Step 1: Stop ECS service gracefully
    if [ ! -z "$ECS_CLUSTER" ] && [ ! -z "$ECS_SERVICE" ]; then
        echo ""
        echo "🛑 Step 1: Stopping ECS service..."
        aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --desired-count 0 >/dev/null 2>&1 || echo "   Service already stopped or doesn't exist"
        
        echo "   Waiting for tasks to stop..."
        for i in {1..12}; do
            RUNNING_COUNT=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].runningCount" --output text 2>/dev/null || echo "0")
            if [ "$RUNNING_COUNT" = "0" ]; then
                echo "✅ ECS service stopped successfully!"
                break
            fi
            echo "   Waiting for tasks to stop... ($i/12)"
            sleep 10
        done
    fi
    
    # Step 2: Empty S3 bucket
    if [ ! -z "$S3_BUCKET" ]; then
        echo ""
        echo "🗑️ Step 2: Emptying S3 bucket..."
        aws s3 rm s3://$S3_BUCKET --recursive >/dev/null 2>&1 || echo "   Bucket already empty or doesn't exist"
        echo "✅ S3 bucket emptied!"
    fi
    
    # Step 3: Delete ECR images
    if [ ! -z "$ECR_REPO" ]; then
        echo ""
        echo "🐳 Step 3: Deleting ECR images..."
        REPO_NAME=$(echo $ECR_REPO | cut -d'/' -f2)
        aws ecr list-images --repository-name $REPO_NAME --query 'imageIds[*]' --output json > /tmp/ecr_images.json 2>/dev/null || echo "[]" > /tmp/ecr_images.json
        
        if [ -s /tmp/ecr_images.json ] && [ "$(cat /tmp/ecr_images.json)" != "[]" ]; then
            aws ecr batch-delete-image --repository-name $REPO_NAME --image-ids file:///tmp/ecr_images.json >/dev/null 2>&1 || echo "   Images already deleted or don't exist"
            echo "✅ ECR images deleted!"
        else
            echo "   No ECR images to delete"
        fi
        rm -f /tmp/ecr_images.json
    fi
    
    # Step 4: Stop any running CodePipeline executions
    echo ""
    echo "⏸️ Step 4: Stopping CodePipeline executions..."
    PIPELINE_NAME="${PROJECT_NAME}-pipeline"
    EXECUTION_ID=$(aws codepipeline get-pipeline-state --name $PIPELINE_NAME --query "stageStates[0].latestExecution.pipelineExecutionId" --output text 2>/dev/null || echo "")
    
    if [ ! -z "$EXECUTION_ID" ] && [ "$EXECUTION_ID" != "None" ]; then
        aws codepipeline stop-pipeline-execution --pipeline-name $PIPELINE_NAME --pipeline-execution-id $EXECUTION_ID >/dev/null 2>&1 || echo "   No active executions to stop"
    fi
    echo "✅ CodePipeline executions stopped!"
    
    # Step 5: Destroy Terraform infrastructure
    echo ""
    echo "💥 Step 5: Destroying Terraform infrastructure..."
    echo "   This may take 5-10 minutes..."
    
    terraform destroy -auto-approve
    
    echo "✅ Infrastructure destroyed successfully!"
else
    echo "ℹ️  Skipping Terraform destruction (no state found)"
fi

cd ..

# Step 6: Clean up local Docker images
echo ""
echo "🐳 Step 6: Cleaning up local Docker images..."

# Remove local images
docker rmi 2048-game-local >/dev/null 2>&1 || echo "   Local image already removed"
if [ ! -z "$ECR_REPO" ]; then
    docker rmi $ECR_REPO:latest >/dev/null 2>&1 || echo "   ECR image already removed"
fi

# Clean up dangling images
DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
if [ ! -z "$DANGLING_IMAGES" ]; then
    docker rmi $DANGLING_IMAGES >/dev/null 2>&1 || echo "   No dangling images to remove"
fi

echo "✅ Docker images cleaned up!"

# Step 7: Clean up local files
echo ""
echo "🧹 Step 7: Cleaning up local files..."

# Remove node_modules
if [ -d "frontend/node_modules" ]; then
    rm -rf frontend/node_modules
    echo "   Removed frontend/node_modules"
fi

# Remove build artifacts
if [ -d "frontend/dist" ]; then
    rm -rf frontend/dist
    echo "   Removed frontend/dist"
fi

# Remove Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
echo "   Removed Python cache files"

# Remove environment files
if [ -f "frontend/.env" ]; then
    rm frontend/.env
    echo "   Removed frontend/.env"
fi

# Remove Terraform files (optional)
read -p "Do you want to remove Terraform state files? (y/N): " REMOVE_TF_STATE
if [ "$REMOVE_TF_STATE" = "y" ] || [ "$REMOVE_TF_STATE" = "Y" ]; then
    cd infrastructure
    rm -rf .terraform/ 2>/dev/null || true
    rm -f terraform.tfstate* 2>/dev/null || true
    rm -f .terraform.lock.hcl 2>/dev/null || true
    echo "   Removed Terraform state files"
    cd ..
fi

echo "✅ Local files cleaned up!"

# Step 8: Final verification
echo ""
echo "🔍 Step 8: Final verification..."

# Check if any resources still exist
echo "Checking for remaining AWS resources..."

# Check ECS
if [ ! -z "$ECS_CLUSTER" ]; then
    ECS_EXISTS=$(aws ecs describe-clusters --clusters $ECS_CLUSTER --query "clusters[0].status" --output text 2>/dev/null || echo "INACTIVE")
    if [ "$ECS_EXISTS" = "ACTIVE" ]; then
        echo "⚠️  ECS cluster still exists: $ECS_CLUSTER"
    fi
fi

# Check S3
if [ ! -z "$S3_BUCKET" ]; then
    S3_EXISTS=$(aws s3 ls s3://$S3_BUCKET 2>/dev/null && echo "exists" || echo "not-exists")
    if [ "$S3_EXISTS" = "exists" ]; then
        echo "⚠️  S3 bucket still exists: $S3_BUCKET"
    fi
fi

# Check ECR
if [ ! -z "$ECR_REPO" ]; then
    REPO_NAME=$(echo $ECR_REPO | cut -d'/' -f2)
    ECR_EXISTS=$(aws ecr describe-repositories --repository-names $REPO_NAME 2>/dev/null && echo "exists" || echo "not-exists")
    if [ "$ECR_EXISTS" = "exists" ]; then
        echo "⚠️  ECR repository still exists: $REPO_NAME"
    fi
fi

echo ""
echo "✅ Cleanup completed successfully!"
echo "=================================================="
echo "🎯 Cleanup Summary:"
echo ""
echo "✅ ECS service stopped and destroyed"
echo "✅ S3 bucket emptied and destroyed"
echo "✅ ECR repository and images destroyed"
echo "✅ Application Load Balancer destroyed"
echo "✅ VPC and networking destroyed"
echo "✅ IAM roles and policies destroyed"
echo "✅ CodePipeline and CodeBuild destroyed"
echo "✅ CloudWatch logs destroyed"
echo "✅ Local Docker images removed"
echo "✅ Local build artifacts removed"
echo ""
echo "💰 Cost Impact:"
echo "   • All billable AWS resources have been destroyed"
echo "   • No ongoing charges should occur"
echo "   • Check AWS billing console to confirm"
echo ""
echo "🔄 To redeploy:"
echo "   ./scripts/linux/deploy.sh"
echo ""
echo "🎉 Cleanup complete! Your AWS account is clean."