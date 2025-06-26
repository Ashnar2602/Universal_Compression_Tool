@echo off
REM Universal ISO Compression Tool - GUI Launcher
REM Launch the Python GUI

cd /d "%~dp0"

REM Check if Python is available
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://python.org
    pause
    exit /b 1
)

REM Check if tkinter is available (should be included with Python)
python -c "import tkinter" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: tkinter is not available
    echo Please reinstall Python with tkinter support
    pause
    exit /b 1
)

REM Launch the GUI
echo Starting Universal ISO Compression Tool GUI...
python gui\main.py

if %ERRORLEVEL% neq 0 (
    echo An error occurred while running the GUI
    pause
)
