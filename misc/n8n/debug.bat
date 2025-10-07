@echo off
echo Debugging n8n DNS setup...
echo.

echo 1. Checking Terraform outputs:
terraform output

echo.
echo 2. Checking DNS resolution:
nslookup n8n.omesh.site

echo.
echo 3. Checking load balancer directly:
for /f "tokens=*" %%i in ('terraform output -raw load_balancer_dns') do (
    echo Load Balancer DNS: %%i
    nslookup %%i
)

echo.
echo 4. Testing direct ALB access:
for /f "tokens=*" %%i in ('terraform output -raw load_balancer_dns') do (
    echo Testing: http://%%i
    curl -I http://%%i
)