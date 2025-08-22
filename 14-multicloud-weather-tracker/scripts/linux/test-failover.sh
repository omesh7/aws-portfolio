#!/bin/bash

echo "==========================================="
echo "🔄 Multi-Cloud Weather Tracker - FAILOVER TEST"
echo "==========================================="
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

# Navigate to infrastructure directory
INFRA_DIR="$PROJECT_ROOT/infrastructure"
if [ ! -d "$INFRA_DIR" ]; then
    echo "❌ [ERROR] Infrastructure directory not found: $INFRA_DIR"
    exit 1
fi

cd "$INFRA_DIR"
echo "📂 Working directory: $(pwd)"
echo

# Check if deployment exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ [ERROR] No deployment found (terraform.tfstate missing)"
    echo "Run deploy.sh first to create infrastructure"
    exit 1
fi

# Check prerequisites
if ! command -v curl >/dev/null 2>&1; then
    echo "❌ [ERROR] curl is required for failover testing"
    echo "Please install curl to test endpoints"
    exit 1
fi

echo "🔍 Retrieving deployment information..."
WEATHER_URL=$(terraform output -raw weather_app_url 2>/dev/null || echo "")
LAMBDA_URL=$(terraform output -raw aws_lambda_function_url_weather_tracker_url 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw aws_cloudfront_distribution_domain_name 2>/dev/null || echo "")

if [ -z "$WEATHER_URL" ]; then
    echo "❌ [ERROR] Weather app URL not found in Terraform outputs"
    exit 1
fi

echo "==========================================="
echo "ENDPOINT INFORMATION"
echo "==========================================="
echo
echo "Primary Infrastructure (AWS):"
echo "  🌐 Frontend URL: $WEATHER_URL"
if [ -n "$CLOUDFRONT_URL" ]; then
    echo "  ☁️  CloudFront: https://$CLOUDFRONT_URL"
fi
if [ -n "$LAMBDA_URL" ]; then
    echo "  🔗 API Endpoint: ${LAMBDA_URL}api/weather"
fi
echo

echo "Secondary Infrastructure (Google Cloud):"
echo "  ℹ️  Status: Not deployed (commented out in main.tf)"
echo "  ℹ️  To enable: Uncomment GCP resources in infrastructure/main.tf"
echo

echo "==========================================="
echo "FAILOVER TESTING"
echo "==========================================="
echo

# Test primary AWS endpoint
if [ -n "$LAMBDA_URL" ]; then
    echo "🧪 [1/3] Testing AWS Lambda API..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${LAMBDA_URL}api/weather?city=london" 2>/dev/null || echo "")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "  ✓ AWS Lambda API: ONLINE (HTTP $HTTP_CODE)"
        AWS_STATUS="ONLINE"
    elif [ -z "$HTTP_CODE" ]; then
        echo "  ✗ AWS Lambda API: NO RESPONSE"
        AWS_STATUS="OFFLINE"
    else
        echo "  ✗ AWS Lambda API: FAILED (HTTP $HTTP_CODE)"
        AWS_STATUS="FAILED"
    fi
else
    echo "  ✗ AWS Lambda API: URL NOT FOUND"
    AWS_STATUS="NOT_FOUND"
fi

echo
echo "🌐 [2/3] Testing AWS Frontend..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$WEATHER_URL" 2>/dev/null || echo "")
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✓ AWS Frontend: ONLINE (HTTP $HTTP_CODE)"
    FRONTEND_STATUS="ONLINE"
elif [ -z "$HTTP_CODE" ]; then
    echo "  ✗ AWS Frontend: NO RESPONSE"
    FRONTEND_STATUS="OFFLINE"
else
    echo "  ✗ AWS Frontend: FAILED (HTTP $HTTP_CODE)"
    FRONTEND_STATUS="FAILED"
fi

echo
echo "☁️  [3/3] Testing Google Cloud (Secondary)..."
echo "  ℹ️  Google Cloud infrastructure not deployed"
echo "  ℹ️  To enable multi-cloud failover:"
echo "     1. Uncomment GCP resources in infrastructure/main.tf"
echo "     2. Configure GCP credentials"
echo "     3. Run deploy.sh"

echo
echo "==========================================="
echo "FAILOVER TEST RESULTS"
echo "==========================================="
echo
echo "Primary (AWS):"
echo "  API Status: $AWS_STATUS"
echo "  Frontend Status: $FRONTEND_STATUS"
echo
echo "Secondary (Google Cloud):"
echo "  Status: NOT DEPLOYED"
echo
echo "==========================================="
echo "MANUAL FAILOVER TESTING GUIDE"
echo "==========================================="
echo
echo "To test failover capabilities:"
echo
echo "1. Enable Google Cloud secondary infrastructure:"
echo "   - Edit infrastructure/main.tf"
echo "   - Uncomment GCP module section"
echo "   - Set gcp_project_id in terraform.tfvars"
echo "   - Run deploy.sh"
echo
echo "2. Simulate AWS failure:"
echo "   - Disable AWS Lambda function in AWS Console"
echo "   - Or modify Cloudflare DNS to point to GCP"
echo
echo "3. Verify failover:"
echo "   - Test weather app URL"
echo "   - Confirm traffic routes to Google Cloud"
echo
echo "4. Restore primary:"
echo "   - Re-enable AWS Lambda function"
echo "   - Verify automatic failback"
echo