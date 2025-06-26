# Universal ISO Compression Tool

Una utility standalone che integra le funzionalità di compressione ISO nei formati CHD e CSO con un'interfaccia grafica moderna e un backend C++ unificato.

## Caratteristiche

- **Backend C++ nativo**: Codice unificato senza dipendenze esterne .exe
- **GUI moderna**: Interfaccia Python + Tkinter semplice e intuitiva
- **Supporto dual-format**: Comprimi file ISO in formato CHD o CSO
- **Elaborazione multipla**: Selezione di file singoli o cartelle intere
- **Multi-threading**: Configurazione thread CPU e file concorrenti
- **Monitoraggio progresso**: Barra di avanzamento e status in tempo reale
- **Configurazione persistente**: Salvataggio automatico delle impostazioni

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

### Backend C++
- Windows 7 o superiore
- MinGW-w64 GCC o MSVC
- Librerie: zlib, lz4

### GUI (opzionale)
- Python 3.7+ (con tkinter incluso)
- Compatibile con Windows 7/8/10/11

## Uso Rapido

### GUI (Raccomandato)
1. **Avvio**: Doppio click su `launch_gui.bat`
2. **Selezione**: "Add Files..." o "Add Folder..." per aggiungere ISO
3. **Configurazione**: Scegli formato (CSO/CHD), thread e opzioni
4. **Output**: Seleziona cartella di destinazione
5. **Avvia**: Click "Start Compression"

### CLI (Avanzato)
```bash
# Compressione CSO
universal-compressor.exe --type=cso --threads=4 --input="game.iso" --output="game.cso"

# Compressione CHD  
universal-compressor.exe --type=chd --threads=4 --input="game.iso" --output="game.chd"
```

## Compilazione

### Backend C++
```bash
# Setup ambiente (solo prima volta)
setup_dev_env.bat

# Build rapido
quick_build.bat

# Build completo
build_cpp.bat

# Build manuale
make
```

### GUI
Nessuna compilazione richiesta - Python script pronto all'uso.

```bash
# Test GUI
python gui\main.py

# Launcher Windows
launch_gui.bat
```

# Con MacPorts
sudo port install zlib lz4
make
```

## Utilizzo

### GUI (Interfaccia Grafica)
1. **Avvio**: `launch_gui.bat` o `python gui\main.py`
2. **Selezione file**: "Add Files..." per file singoli, "Add Folder..." per cartelle
3. **Impostazioni**:
   - Formato: CSO (veloce) o CHD (maggiore compressione)
   - Thread CPU: 1-16 (default: 4)
   - File concorrenti: 1-8 (default: 1)
4. **Output**: Selezione cartella di destinazione
5. **Avvio**: "Start Compression"

### CLI (Riga di comando)
```bash
# Sintassi base
universal-compressor.exe --type=[cso|chd] --input="file.iso" --output="file.ext"

# Esempi CSO
universal-compressor.exe --type=cso --threads=4 --input="game.iso" --output="game.cso"

# Esempi CHD
universal-compressor.exe --type=chd --threads=4 --input="game.iso" --output="game.chd"

# Help completo
universal-compressor.exe --help
```
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

## File e Cartelle

### Struttura progetto
```
Universal-Compression-Tool/
├── gui/                    # Interfaccia grafica Python
│   ├── main.py            # GUI principale  
│   ├── config.json        # Configurazione salvata
│   └── README.md          # Documentazione GUI
├── src/                   # Backend C++
├── bin/                   # Eseguibili compilati
├── launch_gui.bat         # Avvio rapido GUI
├── build_cpp.bat          # Build backend
└── README.md              # Questa documentazione
```

## Risoluzione problemi

### GUI non si avvia
```bash
# Verifica Python
python --version

# Verifica tkinter
python -c "import tkinter"

# Se manca Python, scarica da python.org
```

### Backend non compila
```bash
# Setup ambiente sviluppo
setup_dev_env.bat

# Build con debug
build_cpp.bat --verbose
```

### Errori di compressione
- Verifica che il file ISO sia valido
- Controlla spazio disco disponibile  
- Assicurati di avere permessi di scrittura nella cartella output

## Compatibilità

- **Input**: File ISO, BIN, IMG
- **Output CSO**: Compatibile con PPSSPP, PCSX2, RetroArch
- **Output CHD**: Compatibile con MAME, RetroArch (core MAME)
- **Sistemi**: Windows 7+, Linux, macOS (con backend compilato)

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
