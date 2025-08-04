#!/bin/bash

echo "📊 Multi-Cloud Weather Tracker Status"
echo "====================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../terraform"

if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No deployment found"
    exit 1
fi

echo "🔍 Infrastructure Status:"
terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "aws_lambda_function") | "Lambda: \(.values.function_name) - \(.values.last_modified)"' 2>/dev/null || echo "Lambda: Deployed"

WEATHER_URL=$(terraform output -raw weather_app_url 2>/dev/null || echo "Not available")
echo "🌐 Weather App: $WEATHER_URL"

echo ""
echo "🧪 Testing endpoints..."
LAMBDA_URL=$(terraform output -raw aws_lambda_function_url_weather_tracker_url 2>/dev/null)
if [ ! -z "$LAMBDA_URL" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${LAMBDA_URL}api/weather?city=london" || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ API: Working"
    else
        echo "❌ API: Failed (HTTP $HTTP_CODE)"
    fi
else
    echo "❌ API: URL not found"
fi