@echo off
echo Updating Lambda functions with fixes...

cd /d "%~dp0"

:: Get the function names from Terraform output
echo Getting Lambda function names...
cd infrastructure
for /f "tokens=*" %%i in ('terraform output -raw uploads_lambda_name') do set UPLOAD_FUNCTION=%%i
for /f "tokens=*" %%i in ('terraform output -raw image_recog_lambda_name') do set IMAGE_FUNCTION=%%i
for /f "tokens=*" %%i in ('terraform output -raw get_poem_lambda_name') do set GET_POEM_FUNCTION=project-11-get-poem-handler

cd ..

echo Updating get_poem function: %GET_POEM_FUNCTION%
cd lambda\get_poem
powershell -Command "Compress-Archive -Path *.py -DestinationPath temp.zip -Force"
aws lambda update-function-code --function-name %GET_POEM_FUNCTION% --zip-file fileb://temp.zip
del temp.zip
cd ..\..

echo Updating upload function: %UPLOAD_FUNCTION%
cd lambda\upload
powershell -Command "Compress-Archive -Path *.py -DestinationPath temp.zip -Force"
aws lambda update-function-code --function-name %UPLOAD_FUNCTION% --zip-file fileb://temp.zip
del temp.zip
cd ..\..

echo Updating image_recog function: %IMAGE_FUNCTION%
cd lambda\image_recog
powershell -Command "Compress-Archive -Path *.py -DestinationPath temp.zip -Force"
aws lambda update-function-code --function-name %IMAGE_FUNCTION% --zip-file fileb://temp.zip
del temp.zip
cd ..\..

echo Lambda functions updated successfully!
echo Check CloudWatch logs for debugging information.
pause