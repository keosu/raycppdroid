@echo off
REM 快速开始脚本 - 使用 xmake 构建 raylib Android 项目
REM Quick start script for building raylib Android project with xmake

echo ================================================
echo   Raylib Android Project - Xmake Quick Start
echo ================================================
echo.

REM 检查 xmake 是否安装
where xmake >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] xmake not found! Please install xmake first.
    echo.
    echo Installation options:
    echo   1. scoop install xmake
    echo   2. Download from: https://github.com/xmake-io/xmake/releases
    echo.
    pause
    exit /b 1
)

echo [INFO] xmake found: 
xmake --version
echo.

REM 检查环境变量
echo [INFO] Checking environment variables...
if not defined JAVA_HOME (
    echo [WARNING] JAVA_HOME not set
    set JAVA_HOME=C:\open-jdk
    echo [INFO] Using default: %JAVA_HOME%
)
if not defined ANDROID_HOME (
    echo [WARNING] ANDROID_HOME not set
    set ANDROID_HOME=C:\android-sdk
    echo [INFO] Using default: %ANDROID_HOME%
)
if not defined ANDROID_NDK (
    echo [WARNING] ANDROID_NDK not set
    set ANDROID_NDK=C:\android-ndk
    echo [INFO] Using default: %ANDROID_NDK%
)

echo.
echo Environment:
echo   JAVA_HOME    = %JAVA_HOME%
echo   ANDROID_HOME = %ANDROID_HOME%
echo   ANDROID_NDK  = %ANDROID_NDK%
echo.

REM 显示菜单
:menu
echo ================================================
echo   Choose an action:
echo ================================================
echo   1. Build desktop version (for testing)
echo   2. Build raylib library for Android
echo   3. Build Android shared library
echo   4. Build APK package
echo   5. Install APK to device
echo   6. Monitor device logs
echo   7. Full deploy (build + install + logs)
echo   8. Clean all build files
echo   9. Exit
echo ================================================
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto build_desktop
if "%choice%"=="2" goto build_raylib
if "%choice%"=="3" goto build_android
if "%choice%"=="4" goto build_apk
if "%choice%"=="5" goto install_apk
if "%choice%"=="6" goto logcat
if "%choice%"=="7" goto deploy
if "%choice%"=="8" goto clean
if "%choice%"=="9" goto exit
echo [ERROR] Invalid choice. Please try again.
echo.
goto menu

:build_desktop
echo.
echo [INFO] Building desktop version...
xmake config -p windows
xmake build raylib-desktop
if %errorlevel% equ 0 (
    echo [SUCCESS] Desktop build completed!
    echo [INFO] You can run it with: xmake run raylib-desktop
) else (
    echo [ERROR] Desktop build failed!
)
echo.
pause
goto menu

:build_raylib
echo.
echo [INFO] Building raylib library for Android...
xmake build-raylib --arch=arm64-v8a
if %errorlevel% equ 0 (
    echo [SUCCESS] raylib build completed!
) else (
    echo [ERROR] raylib build failed!
)
echo.
pause
goto menu

:build_android
echo.
echo [INFO] Building Android shared library...
xmake config -p android -a arm64-v8a
xmake build raylib-android
if %errorlevel% equ 0 (
    echo [SUCCESS] Android build completed!
) else (
    echo [ERROR] Android build failed!
)
echo.
pause
goto menu

:build_apk
echo.
echo [INFO] Building APK package...
xmake build-apk --arch=arm64-v8a
if %errorlevel% equ 0 (
    echo [SUCCESS] APK build completed!
    echo [INFO] APK structure created in build/android.rgame/
) else (
    echo [ERROR] APK build failed!
)
echo.
pause
goto menu

:install_apk
echo.
echo [INFO] Installing APK to device...
echo [WARNING] Make sure your device is connected and USB debugging is enabled
adb devices
echo.
xmake install-apk
echo.
pause
goto menu

:logcat
echo.
echo [INFO] Starting logcat monitoring...
echo [INFO] Press Ctrl+C to stop monitoring
xmake logcat
echo.
pause
goto menu

:deploy
echo.
echo [INFO] Starting full deployment...
echo [INFO] This will: build APK -> install -> monitor logs
echo.
xmake deploy
echo.
pause
goto menu

:clean
echo.
echo [INFO] Cleaning all build files...
xmake clean-all
if %errorlevel% equ 0 (
    echo [SUCCESS] Clean completed!
) else (
    echo [ERROR] Clean failed!
)
echo.
pause
goto menu

:exit
echo.
echo [INFO] Thank you for using xmake with raylib!
echo [INFO] For more information, see XMAKE_README.md
echo.
exit /b 0