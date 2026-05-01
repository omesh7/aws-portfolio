#!/bin/bash

echo "==========================================="
echo "📊 Multi-Cloud Weather Tracker - STATUS"
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
    echo "ℹ️  [INFO] No deployment found (terraform.tfstate missing)"
    echo "Run deploy.sh to create infrastructure"
    exit 0
fi

# Check prerequisites for testing
CURL_AVAILABLE=1
if ! command -v curl >/dev/null 2>&1; then
    CURL_AVAILABLE=0
fi

echo "==========================================="
echo "INFRASTRUCTURE STATUS"
echo "==========================================="
echo

# Get Terraform outputs
echo "🔍 Retrieving deployment information..."
WEATHER_URL=$(terraform output -raw weather_app_url 2>/dev/null || echo "")
LAMBDA_URL=$(terraform output -raw aws_lambda_function_url_weather_tracker_url 2>/dev/null || echo "")
S3_BUCKET=$(terraform output -raw aws_s3_bucket 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw aws_cloudfront_distribution_domain_name 2>/dev/null || echo "")

echo "Resources:"
if [ -n "$S3_BUCKET" ]; then
    echo "  🪣 S3 Bucket: $S3_BUCKET"
else
    echo "  🪣 S3 Bucket: [Not found]"
fi

if [ -n "$CLOUDFRONT_URL" ]; then
    echo "  ☁️  CloudFront: $CLOUDFRONT_URL"
else
    echo "  ☁️  CloudFront: [Not found]"
fi

if [ -n "$LAMBDA_URL" ]; then
    echo "  λ Lambda API: $LAMBDA_URL"
else
    echo "  λ Lambda API: [Not found]"
fi

if [ -n "$WEATHER_URL" ]; then
    echo "  🌐 Weather App: $WEATHER_URL"
else
    echo "  🌐 Weather App: [Not available]"
fi

echo
echo "==========================================="
echo "ENDPOINT TESTING"
echo "==========================================="
echo

if [ $CURL_AVAILABLE -eq 0 ]; then
    echo "⚠️  [WARNING] curl not found - cannot test endpoints"
    echo "Install curl to enable endpoint testing"
    exit 0
fi

# Test Lambda API
if [ -n "$LAMBDA_URL" ]; then
    echo "🧪 Testing Lambda API..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${LAMBDA_URL}api/weather?city=london" 2>/dev/null || echo "")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "  ✓ Lambda API: Working (HTTP $HTTP_CODE)"
    elif [ -z "$HTTP_CODE" ]; then
        echo "  ✗ Lambda API: No response"
    else
        echo "  ✗ Lambda API: Failed (HTTP $HTTP_CODE)"
    fi
else
    echo "  ✗ Lambda API: URL not available"
fi

# Test Weather App
if [ -n "$WEATHER_URL" ]; then
    echo "🌐 Testing Weather App..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$WEATHER_URL" 2>/dev/null || echo "")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "  ✓ Weather App: Working (HTTP $HTTP_CODE)"
    elif [ -z "$HTTP_CODE" ]; then
        echo "  ✗ Weather App: No response"
    else
        echo "  ✗ Weather App: Failed (HTTP $HTTP_CODE)"
    fi
else
    echo "  ✗ Weather App: URL not available"
fi

echo
echo "==========================================="
echo "STATUS CHECK COMPLETE"
echo "==========================================="
echo