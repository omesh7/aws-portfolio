#!/bin/bash

PROJECT_NAME="proj-13-2048-game-cp"

echo "🚀 Manually triggering CodePipeline build..."
echo "=========================================="

cd "$(dirname "$0")/../.."
cd infrastructure 2>/dev/null || {
    echo "❌ No infrastructure directory found."
    exit 1
}

if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "❌ No Terraform state found. Infrastructure not deployed."
    exit 1
fi

PIPELINE_NAME=$(terraform output -raw codepipeline_name 2>/dev/null || echo "")

if [ -z "$PIPELINE_NAME" ]; then
    echo "❌ Pipeline name not found in Terraform outputs."
    exit 1
fi

echo "📋 Pipeline: $PIPELINE_NAME"
echo "🔄 Triggering build..."

aws codepipeline start-pipeline-execution --name $PIPELINE_NAME
if [ $? -ne 0 ]; then
    echo "❌ Failed to trigger pipeline"
    exit 1
fi

echo "✅ Build triggered successfully!"
echo ""
echo "📊 Monitor progress:"
echo "   AWS Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$PIPELINE_NAME/view"
echo "   Status script: ./scripts/linux/status.sh"