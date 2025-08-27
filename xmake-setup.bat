@echo off
setlocal enabledelayedexpansion

echo ====================================
echo XMake Android Build Setup Script
echo ====================================
echo.

:: 检查 xmake 是否安装
where xmake >nul 2>&1
if errorlevel 1 (
    echo [ERROR] xmake not found in PATH
    echo Please install xmake from: https://xmake.io/
    echo.
    pause
    exit /b 1
)

echo [OK] xmake found

:: 检查环境变量
set "JAVA_HOME_DEFAULT=C:\open-jdk"
set "ANDROID_SDK_DEFAULT=C:\android-sdk"
set "ANDROID_NDK_DEFAULT=C:\android-ndk"

if "%JAVA_HOME%"=="" (
    set "JAVA_HOME=%JAVA_HOME_DEFAULT%"
    echo [INFO] JAVA_HOME not set, using default: %JAVA_HOME%
) else (
    echo [OK] JAVA_HOME: %JAVA_HOME%
)

if "%ANDROID_SDK_ROOT%"=="" (
    set "ANDROID_SDK_ROOT=%ANDROID_SDK_DEFAULT%"
    echo [INFO] ANDROID_SDK_ROOT not set, using default: %ANDROID_SDK_ROOT%
) else (
    echo [OK] ANDROID_SDK_ROOT: %ANDROID_SDK_ROOT%
)

if "%ANDROID_NDK_ROOT%"=="" (
    set "ANDROID_NDK_ROOT=%ANDROID_NDK_DEFAULT%"
    echo [INFO] ANDROID_NDK_ROOT not set, using default: %ANDROID_NDK_ROOT%
) else (
    echo [OK] ANDROID_NDK_ROOT: %ANDROID_NDK_ROOT%
)

:: 检查目录是否存在
echo.
echo Checking required directories...

if not exist "%JAVA_HOME%" (
    echo [ERROR] Java JDK not found at: %JAVA_HOME%
    echo Please install OpenJDK 21 or set correct JAVA_HOME
    set "MISSING_TOOLS=1"
) else (
    echo [OK] Java JDK found
)

if not exist "%ANDROID_SDK_ROOT%" (
    echo [ERROR] Android SDK not found at: %ANDROID_SDK_ROOT%
    echo Please install Android SDK or run get-android-tools\get-android-tools.bat
    set "MISSING_TOOLS=1"
) else (
    echo [OK] Android SDK found
)

if not exist "%ANDROID_NDK_ROOT%" (
    echo [ERROR] Android NDK not found at: %ANDROID_NDK_ROOT%
    echo Please install Android NDK or run get-android-tools\get-android-tools.bat
    set "MISSING_TOOLS=1"
) else (
    echo [OK] Android NDK found
)

:: 检查具体的工具
if exist "%ANDROID_SDK_ROOT%" (
    if not exist "%ANDROID_SDK_ROOT%\build-tools\36.0.0" (
        echo [WARNING] Android Build Tools 36.0.0 not found
        echo Please install: sdkmanager "build-tools;36.0.0"
    ) else (
        echo [OK] Android Build Tools 36.0.0 found
    )
    
    if not exist "%ANDROID_SDK_ROOT%\platforms\android-36" (
        echo [WARNING] Android Platform 36 not found
        echo Please install: sdkmanager "platforms;android-36"
    ) else (
        echo [OK] Android Platform 36 found
    )
)

echo.
if "%MISSING_TOOLS%"=="1" (
    echo [ERROR] Some required tools are missing!
    echo.
    echo To fix this, you can:
    echo 1. Run: get-android-tools\get-android-tools.bat
    echo 2. Or manually install the missing tools
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] All required tools found!
echo.
echo Available XMake commands:
echo.
echo Desktop build:
echo   xmake build raylib-desktop
echo   xmake run raylib-desktop
echo.
echo Android build:
echo   xmake build-raylib          # Build raylib for Android
echo   xmake build raylib-android  # Build native library
echo   xmake build-apk             # Build complete APK
echo.
echo Android deployment:
echo   xmake install-apk           # Install APK to device
echo   xmake logcat                # Monitor logs
echo   xmake deploy                # Build + Install + Monitor
echo.
echo Cleaning:
echo   xmake clean                 # Clean build files
echo   xmake clean-all             # Clean everything including raylib
echo.
echo For more options: xmake -h
echo.
pause