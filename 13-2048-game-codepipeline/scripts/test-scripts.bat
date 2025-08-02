@echo off
echo Testing Windows Scripts
echo =======================

echo.
echo 1. Testing run.bat with status...
echo n | cmd /c run.bat status
echo Status: %ERRORLEVEL%

echo.
echo 2. Testing run.bat with deploy (prerequisites only)...
echo Checking prerequisites... | cmd /c run.bat deploy
echo Deploy: %ERRORLEVEL%

echo.
echo 3. Testing run.bat with destroy (cancelled)...
echo n | cmd /c run.bat destroy
echo Destroy: %ERRORLEVEL%

echo.
echo All Windows script tests completed!