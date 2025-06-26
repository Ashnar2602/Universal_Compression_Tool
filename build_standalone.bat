@echo off
echo ========================================
echo  Universal ISO Compression Tool
echo  Build Standalone Executables
echo ========================================

:: Check if AutoHotkey is installed
where ahk2exe >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: AutoHotkey not found in PATH
    echo Please restart your command prompt or add AutoHotkey to PATH
    echo Default location: C:\Program Files\AutoHotkey
    pause
    exit /b 1
)

:: Create release directory
if not exist "release" mkdir release
if not exist "release\bin" mkdir release\bin

echo.
echo [1/4] Compiling Enhanced GUI...

:: Compile the main GUI with all dependencies
ahk2exe /in "UniversalCompressionGUI_Enhanced.ahk" /out "release\UniversalCompressionTool.exe" /icon "%~dp0icon.ico" /compress 2

if %errorlevel% neq 0 (
    echo Warning: GUI compilation failed, trying without icon...
    ahk2exe /in "UniversalCompressionGUI_Enhanced.ahk" /out "release\UniversalCompressionTool.exe" /compress 2
)

echo [2/4] Copying CLI backend...
copy "bin\universal-compressor.exe" "release\bin\" >nul
copy "bin\*.dll" "release\bin\" >nul 2>&1

echo [3/4] Copying required files...
copy "README.md" "release\" >nul
copy "LICENSE" "release\" >nul
copy "PROGETTO_COMPLETATO.md" "release\" >nul

:: Copy AutoHotkey dependencies if they exist
copy "ClassImageButton.ahk" "release\" >nul 2>&1
copy "ConsoleClass.ahk" "release\" >nul 2>&1
copy "JSON.ahk" "release\" >nul 2>&1
copy "SelectFolderEx.ahk" "release\" >nul 2>&1

echo [4/4] Creating batch launcher (backup)...

:: Create a simple batch launcher as backup
echo @echo off > "release\Launch_GUI.bat"
echo cd /d "%%~dp0" >> "release\Launch_GUI.bat"
echo if exist "UniversalCompressionTool.exe" ( >> "release\Launch_GUI.bat"
echo     start "" "UniversalCompressionTool.exe" >> "release\Launch_GUI.bat"
echo ) else ( >> "release\Launch_GUI.bat"
echo     echo Error: UniversalCompressionTool.exe not found >> "release\Launch_GUI.bat"
echo     pause >> "release\Launch_GUI.bat"
echo ) >> "release\Launch_GUI.bat"

echo.
echo ========================================
echo  BUILD COMPLETED!
echo ========================================
echo.
echo Release files created in: release\
echo.
echo Main executable: UniversalCompressionTool.exe
echo CLI backend: bin\universal-compressor.exe
echo Backup launcher: Launch_GUI.bat
echo.
echo The tool is now completely standalone!
echo You can copy the 'release' folder to any Windows PC.
echo.
pause
