@echo off
REM Setup completo ambiente di sviluppo per Universal ISO Compression Tool
echo.
echo ======================================
echo  Setup Ambiente di Sviluppo C++
echo ======================================
echo.

REM Controlla se MSYS2 è installato
if exist "C:\msys64\usr\bin\pacman.exe" (
    echo ✓ MSYS2 già installato
) else (
    echo MSYS2 non trovato, installazione in corso...
    winget install MSYS2.MSYS2
    if %errorlevel% neq 0 (
        echo ✗ Errore installazione MSYS2
        pause
        exit /b 1
    )
)

echo.
echo Installazione pacchetti di sviluppo con MSYS2...
echo.

REM Aggiorna il database dei pacchetti e installa gli strumenti necessari
C:\msys64\usr\bin\bash.exe -l -c "pacman -Syu --noconfirm"
C:\msys64\usr\bin\bash.exe -l -c "pacman -S --noconfirm mingw-w64-x86_64-gcc"
C:\msys64\usr\bin\bash.exe -l -c "pacman -S --noconfirm mingw-w64-x86_64-zlib"
C:\msys64\usr\bin\bash.exe -l -c "pacman -S --noconfirm mingw-w64-x86_64-lz4"
C:\msys64\usr\bin\bash.exe -l -c "pacman -S --noconfirm mingw-w64-x86_64-make"
C:\msys64\usr\bin\bash.exe -l -c "pacman -S --noconfirm make"

echo.
echo Aggiornamento PATH per questa sessione...
echo.

REM Aggiungi MSYS2 al PATH temporaneamente
set "PATH=C:\msys64\mingw64\bin;C:\msys64\usr\bin;%PATH%"

echo Verifica installazione...
echo.

REM Test compilatore
C:\msys64\mingw64\bin\g++.exe --version
if %errorlevel% neq 0 (
    echo ✗ Errore: GCC non funziona correttamente
    pause
    exit /b 1
)

REM Test zlib
echo #include ^<zlib.h^> > test_zlib.cpp
echo #include ^<iostream^> >> test_zlib.cpp
echo int main(){std::cout^<^<"zlib version: "^<^<ZLIB_VERSION^<^<std::endl;return 0;} >> test_zlib.cpp

C:\msys64\mingw64\bin\g++.exe test_zlib.cpp -lz -o test_zlib.exe
if %errorlevel% eq 0 (
    echo ✓ Test zlib: OK
    test_zlib.exe
    del test_zlib.cpp test_zlib.exe
) else (
    echo ✗ Test zlib: FAIL
    del test_zlib.cpp
)

echo.
echo ======================================
echo  Setup Completato!
echo ======================================
echo.
echo Strumenti installati:
echo - GCC (MinGW-w64)
echo - zlib
echo - LZ4
echo - make
echo.
echo Per compilare il progetto:
echo 1. Apri MSYS2 MinGW 64-bit terminal
echo 2. Naviga nella cartella del progetto
echo 3. Esegui: make
echo.
echo Oppure usa build_cpp.bat che dovrebbe ora funzionare
echo.

REM Crea script di avvio per MSYS2
echo @echo off > start_msys2_build.bat
echo echo Avvio MSYS2 MinGW 64-bit per compilazione... >> start_msys2_build.bat
echo start "MSYS2 MinGW 64-bit" "C:\msys64\mingw64.exe" >> start_msys2_build.bat

echo ✓ Creato start_msys2_build.bat per aprire l'ambiente di build
echo.

REM Test build del progetto
echo Vuoi testare la compilazione ora? (s/n)
set /p test_build=
if /i "%test_build%"=="s" (
    echo.
    echo Test compilazione...
    call build_cpp.bat
)

echo.
echo Setup completato! 
echo Per sviluppare usa start_msys2_build.bat
pause
