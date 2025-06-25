@echo off
REM Build script per Universal ISO Compression Tool - Versione C++
REM Questo script cerca i compilatori disponibili e tenta la compilazione

echo.
echo ======================================
echo  Universal ISO Compression Tool
echo  Build Script C++
echo ======================================
echo.

echo Cercando compilatori disponibili...

REM Controlla MinGW/MSYS2
where gcc >nul 2>&1
if %errorlevel% == 0 (
    echo Trovato GCC, avvio build con MinGW...
    call :build_mingw
    goto :eof
)

REM Controlla Visual Studio
where cl >nul 2>&1
if %errorlevel% == 0 (
    echo Trovato MSVC, avvio build con Visual Studio...
    call :build_msvc
    goto :eof
)

REM Controlla Clang
where clang++ >nul 2>&1
if %errorlevel% == 0 (
    echo Trovato Clang, avvio build...
    call :build_clang
    goto :eof
)

echo.
echo ERRORE: Nessun compilatore C++ trovato!
echo.
echo Per compilare questo progetto, installa uno dei seguenti:
echo.
echo 1. MinGW-w64 via MSYS2:
echo    - Scarica da: https://www.msys2.org/
echo    - Installa con: pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-zlib
echo.
echo 2. Visual Studio 2019/2022:
echo    - Scarica da: https://visualstudio.microsoft.com/
echo    - Installa il workload "Sviluppo di applicazioni desktop con C++"
echo.
echo 3. Clang:
echo    - Scarica da: https://llvm.org/builds/
echo.
echo Alternativamente, puoi usare gli script wrapper esistenti:
echo - RunPython.bat (richiede Python)
echo - Build.bat (versione AutoHotkey)
echo.
pause
goto :eof

:build_mingw
echo.
echo =========================
echo BUILD CON MINGW
echo =========================
echo.

REM Crea directory
if not exist "bin" mkdir bin
if not exist "obj" mkdir obj

REM Compila i file sorgente
echo Compilando universal_compressor.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/universal_compressor.cpp -o obj/universal_compressor.o
if %errorlevel% neq 0 goto :build_error

echo Compilando cso_compressor.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/cso_compressor.cpp -o obj/cso_compressor.o
if %errorlevel% neq 0 goto :build_error

echo Compilando chd_compressor.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/chd_compressor.cpp -o obj/chd_compressor.o
if %errorlevel% neq 0 goto :build_error

echo Compilando main.cpp...
g++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB -c src/main.cpp -o obj/main.o
if %errorlevel% neq 0 goto :build_error

REM Link finale
echo Linking...
g++ obj/*.o -o bin/universal-compressor.exe -lz
if %errorlevel% neq 0 goto :build_error

echo.
echo ✓ Build completato con successo!
echo Eseguibile: bin\universal-compressor.exe
echo.
bin\universal-compressor.exe --version
echo.
goto :eof

:build_msvc
echo.
echo =========================
echo BUILD CON VISUAL STUDIO
echo =========================
echo.

REM Crea directory
if not exist "bin" mkdir bin
if not exist "obj" mkdir obj

echo Compilando con MSVC...
cl /std:c++17 /O2 /EHsc /Isrc /DHAVE_ZLIB src/*.cpp /Fe:bin/universal-compressor.exe /Fo:obj/
if %errorlevel% neq 0 goto :build_error

echo.
echo ✓ Build completato con successo!
echo Eseguibile: bin\universal-compressor.exe
echo.
bin\universal-compressor.exe --version
echo.
goto :eof

:build_clang
echo.
echo =========================
echo BUILD CON CLANG
echo =========================
echo.

REM Crea directory
if not exist "bin" mkdir bin
if not exist "obj" mkdir obj

REM Compila con Clang
echo Compilando con Clang...
clang++ -std=c++17 -O2 -Wall -Wextra -Isrc -DHAVE_ZLIB src/*.cpp -o bin/universal-compressor.exe -lz
if %errorlevel% neq 0 goto :build_error

echo.
echo ✓ Build completato con successo!
echo Eseguibile: bin\universal-compressor.exe
echo.
bin\universal-compressor.exe --version
echo.
goto :eof

:build_error
echo.
echo ✗ Errore durante la compilazione!
echo.
echo Possibili soluzioni:
echo 1. Assicurati che zlib sia installata
echo 2. Verifica che tutti i file sorgente siano presenti
echo 3. Controlla che il compilatore supporti C++17
echo 4. Su Windows potresti aver bisogno di librerie precompilate
echo.
echo Per installare zlib su Windows:
echo - Con MSYS2: pacman -S mingw-w64-x86_64-zlib
echo - Con vcpkg: vcpkg install zlib
echo.
pause
goto :eof
