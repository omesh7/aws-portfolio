@echo off
echo 🚀 Deploying infrastructure...
cd infrastructure
terraform apply -auto-approve

echo 🌐 Triggering Vercel deployment...
for /f "tokens=*" %%i in ('terraform output -raw vercel_deploy_hook_url 2^>nul') do set DEPLOY_HOOK_URL=%%i
if defined DEPLOY_HOOK_URL (
    curl -X POST "%DEPLOY_HOOK_URL%"
    echo ✅ Vercel deployment triggered!
) else (
    echo ⚠️  No deploy hook found. Push to main branch to deploy.
)