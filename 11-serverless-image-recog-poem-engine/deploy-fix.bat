@echo off
echo Deploying Project 11 fixes...

cd /d "%~dp0"

echo Creating Lambda zip files...

:: Create get_poem zip
cd lambda\get_poem
powershell -Command "Compress-Archive -Path *.py -DestinationPath ..\..\lambda_get_poem.zip -Force"
cd ..\..

:: Create upload zip  
cd lambda\upload
powershell -Command "Compress-Archive -Path *.py -DestinationPath ..\..\lambda_upload.zip -Force"
cd ..\..

:: Create image_recog zip
cd lambda\image_recog
powershell -Command "Compress-Archive -Path *.py -DestinationPath ..\..\lambda_image_recog.zip -Force"
cd ..\..

echo Applying Terraform changes...
cd infrastructure
terraform apply -auto-approve

echo Deployment complete!
echo Check CloudWatch logs for debugging information.
pause