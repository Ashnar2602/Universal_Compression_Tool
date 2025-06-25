@echo off
setlocal enabledelayedexpansion
echo Universal Compression Tool - Build Script
echo ========================================
echo.

echo Checking AutoHotkey installation...
echo.

REM Check if AutoHotkey is installed by looking for it in common locations
set "AHK_FOUND=0"
set "AHK2EXE_PATH="

REM Check in PATH first
where /q Ahk2Exe.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "AHK_FOUND=1"
    set "AHK2EXE_PATH=Ahk2Exe.exe"
    echo ✓ Found Ahk2Exe.exe in PATH
    goto :compile
)

REM Check common AutoHotkey installation paths
set "AHK_PATHS="
set "AHK_PATHS=%AHK_PATHS%;C:\Program Files\AutoHotkey"
set "AHK_PATHS=%AHK_PATHS%;C:\Program Files (x86)\AutoHotkey"
set "AHK_PATHS=%AHK_PATHS%;%LOCALAPPDATA%\Programs\AutoHotkey"
set "AHK_PATHS=%AHK_PATHS%;%PROGRAMFILES%\AutoHotkey"

for %%P in (%AHK_PATHS%) do (
    if exist "%%P\Compiler\Ahk2Exe.exe" (
        set "AHK_FOUND=1"
        set "AHK2EXE_PATH=%%P\Compiler\Ahk2Exe.exe"
        echo ✓ Found AutoHotkey at: %%P
        goto :compile
    )
)

REM If not found, show installation instructions
if %AHK_FOUND% EQU 0 (
    echo ✗ AutoHotkey not found!
    echo.
    echo AutoHotkey is required to compile this application.
    echo.
    echo Please install AutoHotkey from: https://www.autohotkey.com/
    echo.
    echo Alternative: You can run the script directly if AutoHotkey is installed:
    echo   AutoHotkey.exe UniversalCompressor.ahk
    echo.
    echo Or download a pre-compiled version if available.
    echo.
    pause
    exit /b 1
)

:compile
echo.
echo Compiling UniversalCompressor.ahk...
echo Using: !AHK2EXE_PATH!
echo.

REM Check if source file exists
if not exist "UniversalCompressor.ahk" (
    echo ✗ Source file UniversalCompressor.ahk not found!
    echo Make sure you're running this script in the correct directory.
    echo.
    pause
    exit /b 1
)

REM Compile the main script
"!AHK2EXE_PATH!" /in "UniversalCompressor.ahk" /out "UniversalCompressor.exe"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Successfully compiled UniversalCompressor.exe
    echo.
    
    REM Check file size and show info
    if exist "UniversalCompressor.exe" (
        for %%I in (UniversalCompressor.exe) do (
            set "filesize=%%~zI"
            set /a "filesizeMB=!filesize!/1048576"
            echo   File size: !filesize! bytes ^(~!filesizeMB! MB^)
        )
    )
    echo.
    
    echo Build completed successfully!
    echo.
    echo Next steps:
    echo 1. Copy maxcso.exe and chdman.exe to this directory
    echo 2. Run Setup.bat to verify installation
    echo 3. Test the application: UniversalCompressor.exe
    echo 4. Distribute the folder containing all required files
    echo.
) else (
    echo.
    echo ✗ Compilation failed!
    echo.
    echo Possible causes:
    echo - Syntax errors in UniversalCompressor.ahk
    echo - Missing dependencies
    echo - Insufficient permissions
    echo.
    echo Try running the script directly to test:
    echo   AutoHotkey.exe UniversalCompressor.ahk
    echo.
)

echo Press any key to exit...
pause >nul
