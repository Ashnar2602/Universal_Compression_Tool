@echo off
echo Universal ISO Compression Tool - Setup
echo =====================================
echo.

REM Check if required files exist
set MISSING_FILES=

if not exist "maxcso.exe" (
    set MISSING_FILES=%MISSING_FILES%maxcso.exe 
    echo [MISSING] maxcso.exe - Required for CSO compression
)

if not exist "chdman.exe" (
    set MISSING_FILES=%MISSING_FILES%chdman.exe 
    echo [MISSING] chdman.exe - Required for CHD compression
)

if exist "maxcso.exe" (
    echo [OK] maxcso.exe found
)

if exist "chdman.exe" (
    echo [OK] chdman.exe found
)

echo.

if not "%MISSING_FILES%"=="" (
    echo WARNING: Some required files are missing.
    echo Please copy the missing files to this directory:
    echo.
    echo Missing files: %MISSING_FILES%
    echo.
    echo You can find these files in:
    echo - maxcso.exe: From the maxcso-1.13.0 release
    echo - chdman.exe: From MAME distribution or namDHC package
    echo.
    pause
    exit /b 1
)

echo All required files are present!
echo.
echo Starting Universal Compression Tool...
echo.

REM Check if AutoHotkey is installed
where ahk >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Running with AutoHotkey...
    start "" "UniversalCompressor.ahk"
) else (
    if exist "UniversalCompressor.exe" (
        echo Running compiled version...
        start "" "UniversalCompressor.exe"
    ) else (
        echo ERROR: AutoHotkey not found and no compiled version available.
        echo Please install AutoHotkey or use the compiled executable.
        pause
        exit /b 1
    )
)

echo.
echo Setup complete!
pause
