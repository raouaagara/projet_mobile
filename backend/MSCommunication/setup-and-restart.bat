@echo off
echo ========================================
echo Setting up File Upload for MSCommunication
echo ========================================
echo.

REM Create uploads directory
echo Creating uploads directory...
if not exist "uploads" (
    mkdir uploads
    echo ✓ Created uploads directory
) else (
    echo ✓ uploads directory already exists
)
echo.

echo ========================================
echo IMPORTANT: Restart your backend server!
echo ========================================
echo.
echo 1. Stop the current server (Ctrl+C)
echo 2. Run: mvn spring-boot:run
echo.
echo After restart, look for this message:
echo "Serving files from: [path]/uploads/"
echo.
echo Then upload a NEW image to test!
echo ========================================
pause
