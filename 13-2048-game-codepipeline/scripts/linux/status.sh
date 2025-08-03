#!/bin/bash

# 2048 Game CI/CD Pipeline - Status Check Script (Linux)
# This script checks the health and status of all deployed resources

PROJECT_NAME="proj-13-2048-game-cp"
REGION="ap-south-1"

echo "📊 2048 Game CI/CD Pipeline - Status Check"
echo "=================================================="

# Check if infrastructure exists
cd ../infrastructure 2>/dev/null || {
    echo "❌ No infrastructure directory found. Run from project root."
    echo ""
    echo "🚀 To deploy: ./scripts/linux/deploy.sh"
    exit 1
}

if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "❌ No Terraform state found. Infrastructure not deployed."
    echo ""
    echo "🚀 To deploy: ./scripts/linux/deploy.sh"
    exit 1
fi

# Get resource information
echo "🔍 Getting resource information..."
ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
API_URL=$(terraform output -raw api_url 2>/dev/null || echo "")

cd ..

echo ""
echo "🏗️ Infrastructure Status:"
echo "   ECR Repository: $ECR_REPO"
echo "   ECS Cluster: $ECS_CLUSTER"
echo "   ECS Service: $ECS_SERVICE"
echo "   S3 Bucket: $S3_BUCKET"
echo "   API URL: $API_URL"

# Check ECS Service
echo ""
echo "🐳 ECS Service Status:"
if [ ! -z "$ECS_CLUSTER" ] && [ ! -z "$ECS_SERVICE" ]; then
    ECS_STATUS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].{status:status,running:runningCount,desired:desiredCount}" --output table 2>/dev/null || echo "Service not found")
    echo "$ECS_STATUS"
else
    echo "❌ ECS service information not available"
fi

# Check Load Balancer Health
echo ""
echo "⚖️ Load Balancer Target Health:"
ALB_TG_ARN=$(terraform output -raw target_group_arn 2>/dev/null || echo "")
if [ ! -z "$ALB_TG_ARN" ] && [ "$ALB_TG_ARN" != "None" ]; then
    TARGET_HEALTH=$(aws elbv2 describe-target-health --target-group-arn $ALB_TG_ARN --query "TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State}" --output table 2>/dev/null || echo "No targets found")
    echo "$TARGET_HEALTH"
else
    echo "❌ Load balancer target group not found"
fi

# Check API Health
echo ""
echo "🔗 API Health Check:"
if [ ! -z "$API_URL" ]; then
    API_RESPONSE=$(curl -s --max-time 10 $API_URL 2>/dev/null || echo "failed")
    if [[ $API_RESPONSE == *"2048 Game API"* ]]; then
        echo "✅ API is healthy and responding"
        echo "   Response: $API_RESPONSE"
    else
        echo "❌ API is not responding correctly"
        echo "   Response: $API_RESPONSE"
    fi
else
    echo "❌ API URL not available"
fi

# Check Frontend
echo ""
echo "🎨 Frontend Status:"
if [ ! -z "$S3_BUCKET" ]; then
    FRONTEND_URL="http://$S3_BUCKET.s3-website.$REGION.amazonaws.com"
    echo "   Frontend URL: $FRONTEND_URL"
    
    # Check if S3 bucket has files
    FILE_COUNT=$(aws s3 ls s3://$S3_BUCKET --recursive | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "✅ Frontend deployed ($FILE_COUNT files in S3)"
    else
        echo "⚠️ Frontend bucket is empty"
    fi
else
    echo "❌ S3 bucket information not available"
fi

# Check CodePipeline
echo ""
echo "🔄 CodePipeline Status:"
PIPELINE_NAME="${PROJECT_NAME}-pipeline"
PIPELINE_STATUS=$(aws codepipeline get-pipeline-state --name $PIPELINE_NAME --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" --output table 2>/dev/null || echo "Pipeline not found")
echo "$PIPELINE_STATUS"

# Check recent builds
echo ""
echo "🔨 Recent CodeBuild Executions:"
BUILD_PROJECT="${PROJECT_NAME}-build"
RECENT_BUILDS=$(aws codebuild list-builds-for-project --project-name $BUILD_PROJECT --sort-order DESCENDING --max-items 3 --query "ids" --output table 2>/dev/null || echo "No builds found")
echo "$RECENT_BUILDS"

# Resource costs (approximate)
echo ""
echo "💰 Estimated Monthly Costs:"
echo "   ECS Fargate (256 CPU, 512MB): ~$15-20"
echo "   Application Load Balancer: ~$16"
echo "   S3 Storage (1GB): ~$0.02"
echo "   ECR Storage (1GB): ~$0.10"
echo "   CodePipeline: ~$1"
echo "   Data Transfer: ~$1-5"
echo "   --------------------------------"
echo "   Total Estimated: ~$33-42/month"

# Quick actions
echo ""
echo "🛠️ Quick Actions:"
echo "   View logs: aws logs tail \"/ecs/$PROJECT_NAME\" --follow"
echo "   Force deployment: aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment"
echo "   Trigger pipeline: aws codepipeline start-pipeline-execution --name $PIPELINE_NAME"
echo ""
echo "📊 Monitoring:"
echo "   ECS Console: https://console.aws.amazon.com/ecs/home?region=$REGION#/clusters/$ECS_CLUSTER/services"
echo "   Pipeline Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$PIPELINE_NAME/view"
echo ""
echo "🧹 Cleanup:"
echo "   ./scripts/linux/destroy.sh"