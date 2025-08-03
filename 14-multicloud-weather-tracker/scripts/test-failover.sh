#!/bin/bash

# Test script for disaster recovery failover

set -e

if [ -z "$1" ]; then
    echo "❌ Please provide your domain name"
    echo "Usage: ./test-failover.sh your-domain.com"
    exit 1
fi

DOMAIN=$1

echo "🧪 Testing Multi-Cloud Failover for $DOMAIN"
echo "============================================"

# Test primary endpoint (AWS)
echo "🔍 Testing primary endpoint (AWS)..."
PRIMARY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN || echo "000")

if [ "$PRIMARY_STATUS" = "200" ]; then
    echo "✅ Primary endpoint is healthy (HTTP $PRIMARY_STATUS)"
else
    echo "❌ Primary endpoint is down (HTTP $PRIMARY_STATUS)"
fi

# Check DNS resolution
echo "🔍 Checking DNS resolution..."
dig +short $DOMAIN

# Test health check endpoint
echo "🔍 Testing health check..."
curl -s -I https://$DOMAIN | head -n 1

# Simulate failover test
echo ""
echo "🔄 To test failover manually:"
echo "   1. Temporarily disable AWS CloudFront distribution"
echo "   2. Wait 3-5 minutes for health check to fail"
echo "   3. Access $DOMAIN - should serve from Azure"
echo "   4. Re-enable AWS CloudFront"
echo "   5. Wait for health check to recover"

echo ""
echo "📊 Monitoring commands:"
echo "   Watch DNS: watch -n 5 'dig +short $DOMAIN'"
echo "   Check status: curl -s -I https://$DOMAIN | head -n 1"