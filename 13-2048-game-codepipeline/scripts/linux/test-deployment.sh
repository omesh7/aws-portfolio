#!/bin/bash

PROJECT_NAME="proj-13-2048-game-cp"
REGION="ap-south-1"

echo "🧪 Testing 2048 Game deployment..."
echo "================================="

cd "$(dirname "$0")/../.."
cd infrastructure 2>/dev/null || {
    echo "❌ No infrastructure directory found."
    exit 1
}

if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "❌ No Terraform state found. Infrastructure not deployed."
    exit 1
fi

echo "📋 Getting deployment URLs..."
API_URL=$(terraform output -raw api_url 2>/dev/null || echo "")
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")

if [ -z "$API_URL" ]; then
    echo "❌ API URL not found"
    exit 1
fi

FRONTEND_URL="http://$S3_BUCKET.s3-website.$REGION.amazonaws.com"

echo ""
echo "🔗 Testing API endpoint..."
echo "API URL: $API_URL"

API_RESPONSE=$(curl -s --max-time 10 $API_URL 2>/dev/null || echo "failed")
if [[ $API_RESPONSE == *"2048 Game API"* ]]; then
    echo "✅ [PASS] API health check"
else
    echo "❌ [FAIL] API health check - Response: $API_RESPONSE"
fi

echo ""
echo "🎮 Testing game creation..."
GAME_RESPONSE=$(curl -s --max-time 10 -X POST -H "Content-Type: application/json" -d '{"action":"new"}' $API_URL 2>/dev/null || echo "failed")
if [[ $GAME_RESPONSE == *"success"*"true"* ]]; then
    echo "✅ [PASS] Game creation test"
else
    echo "❌ [FAIL] Game creation test - Response: $GAME_RESPONSE"
fi

echo ""
echo "🎨 Testing frontend deployment..."
echo "Frontend URL: $FRONTEND_URL"

FRONTEND_STATUS=$(curl -s --max-time 10 -I $FRONTEND_URL 2>/dev/null | grep "200 OK" || echo "failed")
if [ "$FRONTEND_STATUS" != "failed" ]; then
    echo "✅ [PASS] Frontend accessibility"
else
    echo "❌ [FAIL] Frontend accessibility"
fi

echo ""
echo "📁 Testing S3 bucket contents..."
FILE_COUNT=$(aws s3 ls s3://$S3_BUCKET --recursive | wc -l)
if [ "$FILE_COUNT" -gt 0 ]; then
    echo "✅ [PASS] Frontend files deployed ($FILE_COUNT files)"
else
    echo "❌ [FAIL] Frontend files missing"
fi

echo ""
echo "================================="
echo "📊 Test Summary:"
echo "   API URL: $API_URL"
echo "   Frontend URL: $FRONTEND_URL"
echo ""
echo "🧪 Manual test steps:"
echo "   1. Open frontend URL in browser"
echo "   2. Click 'New Game' button"
echo "   3. Use arrow keys to play"
echo "   4. Verify score updates"