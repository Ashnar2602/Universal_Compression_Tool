# Universal ISO Compression Tool

Una utility standalone che integra le funzionalità di compressione ISO nei formati CHD e CSO in un'unica applicazione nativa, senza dipendenze esterne.

## Caratteristiche

- **Integrazione nativa**: Codice unificato che combina maxcso e chdman direttamente
- **Zero dipendenze esterne**: Non richiede file eseguibili separati
- **Supporto dual-format**: Comprimi file ISO in formato CHD o CSO
- **Interfaccia unificata**: CLI intuitiva per entrambi i formati
- **Elaborazione batch**: Comprimi più file contemporaneamente
- **Opzioni avanzate**: Configurazioni personalizzabili per ogni formato
- **Performance ottimizzate**: Multi-threading e algoritmi di compressione ottimizzati

## Formati supportati

### CSO (Compressed ISO)
- **Utilizzo**: PlayStation Portable e emulatori PS2
- **Vantaggi**: Rapidi tempi di decompressione, buon rapporto di compressione
- **Formati di output**: CSO1, CSO2, ZSO, DAX
- **Algoritmi**: Zlib, 7-Zip deflate, Zopfli, LZ4, LibDeflate

### CHD (Compressed Hunks of Data)
- **Utilizzo**: MAME e emulatori di sistemi arcade/computer
- **Vantaggi**: Eccellente compressione per immagini di dischi rigidi
- **Codec**: CDLZ, CDZL, CDFL, LZMA
- **Configurabile**: Dimensioni hunk personalizzabili

## Requisiti di sistema

- Windows 7 o superiore (build Windows)
- Linux (build Linux)  
- macOS (build macOS)
- Compilatore C++20 compatibile
- Librerie: zlib, liblz4 (opzionale)

## Compilazione

### Prerequisiti
- Compilatore C++20 (GCC 10+, Clang 10+, MSVC 2019+)
- CMake 3.15+ (opzionale)
- Git (per clonare le dipendenze)

### Dipendenze
- **zlib**: Per compressione CSO e CHD
- **liblz4**: Per supporto LZ4 in CSO (opzionale)

### Build su Windows
```bash
# Con MinGW/MSYS2
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-zlib mingw-w64-x86_64-lz4
make

# Con Visual Studio (usando vcpkg)
vcpkg install zlib lz4
make
```

### Build su Linux
```bash
# Ubuntu/Debian
sudo apt-get install build-essential zlib1g-dev liblz4-dev
make

# CentOS/RHEL
sudo yum install gcc-c++ zlib-devel lz4-devel
make

# Arch Linux
sudo pacman -S gcc zlib lz4
make
```

### Build su macOS
```bash
# Con Homebrew
brew install zlib lz4
make

# Con MacPorts
sudo port install zlib lz4
make
```

## Utilizzo

### Sintassi di base
```bash
universal-compressor [opzioni] file.iso [file2.iso ...]
```

### Esempi

#### Compressione CSO
```bash
# Compressione CSO standard
universal-compressor game.iso

# Compressione CSO con formato specifico
universal-compressor --type=cso --cso-format=zso game.iso

# Compressione batch con opzioni avanzate
universal-compressor --cso-threads=8 --cso-fast *.iso

# Compressione CSO2 con LZ4
universal-compressor --type=cso --cso-format=cso2 game.iso
```

#### Compressione CHD
```bash
# Compressione CHD standard
universal-compressor --type=chd game.iso

# CHD con dimensione hunk personalizzata
universal-compressor --type=chd --chd-hunk=32768 game.iso

# CHD con codec specifico
universal-compressor --type=chd --chd-compression=cdlz,cdzl cd-game.iso
```

#### Opzioni avanzate
```bash
# Output in cartella specifica
universal-compressor --output=./compressed --delete-input *.iso

# Modalità verbose
universal-compressor --verbose --type=chd game.iso

# Elaborazione batch silenziosa
universal-compressor --quiet --type=cso *.iso
```

## Opzioni disponibili

### Opzioni generali
- `--help, -h`: Mostra aiuto
- `--version, -v`: Mostra versione
- `--type=TIPO`: Tipo compressione (cso/chd)
- `--output=CARTELLA`: Cartella output
- `--delete-input`: Elimina file sorgente dopo compressione
- `--verbose`: Output dettagliato
- `--quiet`: Output silenzioso

### Opzioni CSO
- `--cso-format=FMT`: Formato (cso1, cso2, zso, dax)
- `--cso-threads=N`: Numero thread (default: 4)
- `--cso-block=SIZE`: Dimensione blocco (default: auto)
- `--cso-fast`: Modalità veloce
- `--cso-no-zlib`: Disabilita zlib
- `--cso-no-7zip`: Disabilita 7zip
- `--cso-no-lz4`: Disabilita LZ4

### Opzioni CHD
- `--chd-hunk=SIZE`: Dimensione hunk in bytes (default: 19584)
- `--chd-processors=N`: Numero processori (default: 4)
- `--chd-compression=CODECS`: Codec separati da virgola (cdlz,cdzl,cdfl)
- `--chd-no-force`: Non forzare sovrascrittura

## Architettura tecnica

### Integrazione codice sorgente
- **maxcso**: Codice C++ integrato direttamente per compressione CSO
- **chdman**: Logica CHD estratta e adattata da MAME
- **Unificazione**: Interfaccia comune per entrambi i formati

### Prestazioni CSO
- Multi-threading nativo per elaborazione parallela
- Supporto algoritmi: Zlib, 7-Zip, Zopfli, LZ4, LibDeflate
- Ottimizzazioni specifiche per settori PSP/PS2
- Heuristics per determinare compressibilità

### Prestazioni CHD
- Gestione hunk ottimizzata per CD/DVD
- Supporto metadati completo (CD-DA, Mode1/2, ecc.)
- Codec multipli con fallback automatico
- Checksum e validazione integrità

## Risoluzione problemi

### Errori di compilazione
```bash
# Mancano librerie di sviluppo
sudo apt-get install build-essential zlib1g-dev

# Versione C++ non supportata
export CXXFLAGS="-std=c++20"
```

### Errori di compressione
- Verifica che il file ISO sia valido e non corrotto
- Assicurati di avere spazio sufficiente nella cartella output
- Controlla i permessi di scrittura

### Performance
- Usa `--cso-threads` per regolare parallelismo
- Modalità `--cso-fast` per velocità maggiore
- Dimensione hunk CHD ottimale: 19584-65536 bytes

## Crediti e licenze

- **maxcso**: Sviluppato da unknownbrackets - [Licenza originale](https://github.com/unknownbrackets/maxcso)
- **MAME/chdman**: Progetto MAME team - [Licenza MAME](https://github.com/mamedev/mame)
- **Universal Compression Tool**: Integrazione unificata dei codici sorgente

## Compatibilità

- **CSO**: Compatibile con PPSSPP, PCSX2, RetroArch
- **CHD**: Compatibile con MAME, RetroArch (core MAME)
- **Input**: ISO, BIN/CUE, IMG
- **Piattaforme**: Windows, Linux, macOS

## Contributi

1. Fork del repository
2. Crea branch per feature (`git checkout -b feature/AmazingFeature`)
3. Commit delle modifiche (`git commit -m 'Add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri Pull Request

## Licenza

Questo progetto rispetta le licenze originali di maxcso e MAME. Consulta i file LICENSE dei progetti originali per dettagli specifici.

## Versione

- **Versione attuale**: 1.0.0
- **Data rilascio**: Giugno 2025
- **Compatibilità**: C++20, multi-piattaforma

---

Per supporto tecnico, consulta la documentazione o apri un issue su GitHub.
