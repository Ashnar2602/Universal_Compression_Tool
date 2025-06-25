@echo off
echo Universal Compression Tool - Python Version
echo ==========================================
echo.

echo Checking Python installation...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Python not found!
    echo.
    echo Python is required to run this application.
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

echo ✓ Python found
python --version

echo.
echo Checking tkinter (GUI library)...

python -c "import tkinter; print('✓ tkinter available')" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ✗ tkinter not available!
    echo.
    echo tkinter is required for the GUI. It's usually included with Python.
    echo If you're on Linux, you might need to install python3-tk.
    echo.
    pause
    exit /b 1
)

echo.
echo Checking required executables...

set MISSING_FILES=
if not exist "maxcso.exe" (
    set MISSING_FILES=maxcso.exe 
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
    echo The application will start but compression will fail for missing tools.
    echo.
    echo Missing files: %MISSING_FILES%
    echo.
    echo You can find these files in:
    echo - maxcso.exe: From the maxcso-1.13.0 release
    echo - chdman.exe: From MAME distribution or namDHC package
    echo.
)

echo Starting Universal Compression Tool (Python version)...
echo.

if not exist "UniversalCompressor.py" (
    echo ✗ UniversalCompressor.py not found!
    echo Make sure you're running this script in the correct directory.
    echo.
    pause
    exit /b 1
)

python UniversalCompressor.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ✗ Application encountered an error.
    echo Check the console output above for details.
    echo.
    pause
)

echo.
echo Application closed.
pause
