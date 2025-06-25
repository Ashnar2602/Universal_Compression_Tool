@echo off
echo Universal Compression Tool - Direct Run
echo =======================================
echo.

echo Checking AutoHotkey installation...
echo.

REM Check if AutoHotkey executable exists
set "AHK_FOUND=0"
set "AHK_PATH="

REM Check in PATH first
where /q AutoHotkey.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "AHK_FOUND=1"
    set "AHK_PATH=AutoHotkey.exe"
    echo ✓ Found AutoHotkey.exe in PATH
    goto :run
)

REM Check common AutoHotkey installation paths
set "AHK_PATHS="
set "AHK_PATHS=%AHK_PATHS%;C:\Program Files\AutoHotkey"
set "AHK_PATHS=%AHK_PATHS%;C:\Program Files (x86)\AutoHotkey"
set "AHK_PATHS=%AHK_PATHS%;%LOCALAPPDATA%\Programs\AutoHotkey"
set "AHK_PATHS=%AHK_PATHS%;%PROGRAMFILES%\AutoHotkey"

for %%P in (%AHK_PATHS%) do (
    if exist "%%P\AutoHotkey.exe" (
        set "AHK_FOUND=1"
        set "AHK_PATH=%%P\AutoHotkey.exe"
        echo ✓ Found AutoHotkey at: %%P
        goto :run
    )
)

REM If not found, show installation instructions
if %AHK_FOUND% EQU 0 (
    echo ✗ AutoHotkey not found!
    echo.
    echo AutoHotkey is required to run this application.
    echo.
    echo Please install AutoHotkey from: https://www.autohotkey.com/
    echo After installation, try running this script again.
    echo.
    pause
    exit /b 1
)

:run
echo.
echo Starting Universal Compression Tool...
echo.

REM Check if source file exists
if not exist "UniversalCompressor.ahk" (
    echo ✗ Source file UniversalCompressor.ahk not found!
    echo Make sure you're running this script in the correct directory.
    echo.
    pause
    exit /b 1
)

REM Run the AutoHotkey script
echo Running: "%AHK_PATH%" "UniversalCompressor.ahk"
echo.

start "" "%AHK_PATH%" "UniversalCompressor.ahk"

if %ERRORLEVEL% EQU 0 (
    echo ✓ Application started successfully!
    echo.
    echo The Universal Compression Tool should now be running.
    echo If you encounter any errors, check the console for details.
) else (
    echo ✗ Failed to start the application!
    echo.
    echo Please check for errors in UniversalCompressor.ahk
)

echo.
echo Press any key to exit...
pause >nul
