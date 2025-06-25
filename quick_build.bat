@echo off
REM Quick build script per Windows con MSYS2
REM Questo script imposta automaticamente il PATH per MinGW e compila il progetto

echo.
echo ======================================
echo  Universal ISO Compression Tool
echo  Quick Build (MSYS2)
echo ======================================
echo.

REM Imposta PATH per MSYS2 MinGW64
set PATH=C:\msys64\mingw64\bin;%PATH%

REM Verifica che GCC sia disponibile
gcc --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRORE: GCC non trovato! 
    echo Assicurati che MSYS2 sia installato in C:\msys64
    echo Per installare MSYS2: winget install MSYS2.MSYS2
    pause
    exit /b 1
)

echo GCC trovato, avvio compilazione...
echo.

REM Crea directory
if not exist "bin" mkdir bin
if not exist "obj" mkdir obj

REM Compila i file sorgente
echo [1/4] Compilando universal_compressor.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/universal_compressor.cpp -o obj/universal_compressor.o
if %errorlevel% neq 0 goto :build_error

echo [2/4] Compilando cso_compressor.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/cso_compressor.cpp -o obj/cso_compressor.o
if %errorlevel% neq 0 goto :build_error

echo [3/4] Compilando chd_compressor.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/chd_compressor.cpp -o obj/chd_compressor.o
if %errorlevel% neq 0 goto :build_error

echo [4/4] Compilando main.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/main.cpp -o obj/main.o
if %errorlevel% neq 0 goto :build_error

REM Link finale
echo [5/5] Linking...
g++ obj/*.o -o bin/universal-compressor.exe -lz
if %errorlevel% neq 0 goto :build_error

echo.
echo ✓ Build completato con successo!
echo Eseguibile: bin\universal-compressor.exe
echo.

REM Testa l'eseguibile
echo Testando l'eseguibile...
bin\universal-compressor.exe --version
echo.

echo Build completato! Puoi ora utilizzare:
echo   bin\universal-compressor.exe --help
echo   bin\universal-compressor.exe file.iso
echo.
goto :eof

:build_error
echo.
echo ✗ Errore durante la compilazione!
echo.
echo Soluzioni possibili:
echo 1. Verifica che zlib sia installata: pacman -Q mingw-w64-x86_64-zlib
echo 2. Controlla che tutti i file sorgente siano presenti in src/
echo 3. Assicurati che il compilatore supporti C++17
echo.
pause
exit /b 1
