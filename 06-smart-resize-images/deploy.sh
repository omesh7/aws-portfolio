#!/bin/bash
set -e

echo "🚀 Deploying infrastructure..."
cd infrastructure
terraform apply -auto-approve

echo "🌐 Triggering Vercel deployment..."
DEPLOY_HOOK_URL=$(terraform output -raw vercel_deploy_hook_url 2>/dev/null || echo "")
if [ -n "$DEPLOY_HOOK_URL" ]; then
    curl -X POST "$DEPLOY_HOOK_URL"
    echo "✅ Vercel deployment triggered!"
else
    echo "⚠️  No deploy hook found. Push to main branch to deploy."
fi