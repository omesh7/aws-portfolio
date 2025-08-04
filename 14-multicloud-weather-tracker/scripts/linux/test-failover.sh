#!/bin/bash

echo "🔄 Testing Multi-Cloud Failover"
echo "==============================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../terraform"

WEATHER_URL=$(terraform output -raw weather_app_url 2>/dev/null)
LAMBDA_URL=$(terraform output -raw aws_lambda_function_url_weather_tracker_url 2>/dev/null)

if [ -z "$WEATHER_URL" ] || [ -z "$LAMBDA_URL" ]; then
    echo "❌ Deployment not found"
    exit 1
fi

echo "🧪 Testing primary endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${LAMBDA_URL}api/weather?city=london" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Primary AWS Lambda: Working"
else
    echo "❌ Primary AWS Lambda: Failed (HTTP $HTTP_CODE)"
fi

echo ""
echo "🌐 Frontend URL: $WEATHER_URL"
echo "🔗 API URL: ${LAMBDA_URL}api/weather"

echo ""
echo "📋 Failover Test Results:"
echo "- Primary (AWS): $([ "$HTTP_CODE" = "200" ] && echo "✅ Online" || echo "❌ Offline")"
echo ""
echo "💡 To test failover manually:"
echo "   1. Disable AWS Lambda function"
echo "   2. Check if traffic routes to backup"
echo "   3. Re-enable AWS Lambda"