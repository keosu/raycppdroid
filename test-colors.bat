@echo off
setlocal enabledelayedexpansion

echo ====================================
echo Testing Makefile Color Output
echo ====================================
echo.

:: Enable ANSI colors in Windows terminal
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

echo Testing color support...
echo.

:: Test color definitions using proper escape sequences
echo Testing colors (if you see colors, ANSI is supported):
echo.

:: Use actual ESC character (ASCII 27) for colors
set "ESC="
echo %ESC%[31m[ERROR]%ESC%[0m Red text (error)
echo %ESC%[32m[SUCCESS]%ESC%[0m Green text (success) 
echo %ESC%[33m[WARNING]%ESC%[0m Yellow text (warning)
echo %ESC%[34m[INFO]%ESC%[0m Blue text (info)
echo %ESC%[36m[STEP]%ESC%[0m Cyan text (step)
echo %ESC%[37m[NORMAL]%ESC%[0m White text (normal)

echo.
echo Alternative: Using PowerShell for color output
echo.

:: Use PowerShell for reliable color output
powershell -Command "Write-Host '[ERROR]' -ForegroundColor Red -NoNewline; Write-Host ' Red text (error)'"
powershell -Command "Write-Host '[SUCCESS]' -ForegroundColor Green -NoNewline; Write-Host ' Green text (success)'"
powershell -Command "Write-Host '[WARNING]' -ForegroundColor Yellow -NoNewline; Write-Host ' Yellow text (warning)'"
powershell -Command "Write-Host '[INFO]' -ForegroundColor Blue -NoNewline; Write-Host ' Blue text (info)'"
powershell -Command "Write-Host '[STEP]' -ForegroundColor Cyan -NoNewline; Write-Host ' Cyan text (step)'"
powershell -Command "Write-Host '[NORMAL]' -ForegroundColor White -NoNewline; Write-Host ' White text (normal)'"

echo.
echo.
echo Note: In traditional CMD, colors may not display correctly.
echo Try running this in:
echo - Windows Terminal
echo - PowerShell
echo - VSCode Terminal
echo.

echo Testing Makefile help command...
echo.

:: Change to project directory and run help
cd /d "c:\Users\Administrator\learn\raycppdroid"

if exist Makefile (
    echo Running 'make help'...
    echo.
    make help
    echo.
    echo The Makefile uses simple text prefixes like [STEP], [INFO], [OK]
    echo which work well in all terminals, even without color support.
) else (
    echo ERROR: Makefile not found in current directory
    echo Current directory: %CD%
)

echo.
echo ====================================
echo Test completed
echo ====================================
echo.
echo TIP: For better color support, use:
echo - Windows Terminal (recommended)
echo - PowerShell 7+
echo - Visual Studio Code Terminal
echo.
pause