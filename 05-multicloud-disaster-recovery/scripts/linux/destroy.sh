#!/bin/bash

set -e

echo "==========================================="
echo "🗑️  Multi-Cloud Weather Tracker - DESTROY"
echo "==========================================="
echo
echo "⚠️  WARNING: This will permanently delete all resources!"
echo
read -p "Type 'yes' to confirm destruction: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Destruction cancelled."
    exit 0
fi
echo

# Get absolute path to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../../14-multicloud-weather-tracker"
if [ ! -d "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$SCRIPT_DIR/../.."
fi
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ Error: Cannot find project root directory"
    exit 1
fi

echo "📁 Project root: $PROJECT_ROOT"
echo

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v terraform >/dev/null 2>&1; then
    echo "❌ [ERROR] Terraform is required but not found in PATH"
    exit 1
fi
echo "✅ [OK] Terraform found"

if ! command -v aws >/dev/null 2>&1; then
    echo "❌ [ERROR] AWS CLI is required but not found in PATH"
    exit 1
fi
echo "✅ [OK] AWS CLI found"
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

# Get S3 bucket name before destroying (for cleanup)
echo "🔍 Getting resource information..."
AWS_BUCKET=$(terraform output -raw aws_s3_bucket 2>/dev/null || echo "")

if [ -n "$AWS_BUCKET" ]; then
    echo "🪣 Found S3 bucket: $AWS_BUCKET"
    echo "🧽 Emptying S3 bucket before destruction..."
    if aws s3 rm s3://$AWS_BUCKET/ --recursive; then
        echo "✅ [OK] S3 bucket emptied"
    else
        echo "⚠️  [WARNING] Failed to empty S3 bucket, continuing with destruction..."
    fi
else
    echo "ℹ️  [INFO] No S3 bucket found in Terraform state"
fi
echo

echo "🗑️  Destroying infrastructure..."
if ! terraform destroy -auto-approve; then
    echo "❌ [ERROR] Terraform destroy failed"
    echo "You may need to manually clean up some resources"
    exit 1
fi

echo
echo "==========================================="
echo "✅ Infrastructure destroyed successfully!"
echo "==========================================="
echo