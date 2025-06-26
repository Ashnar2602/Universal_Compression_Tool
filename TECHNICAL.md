# Universal ISO Compression Tool - Documentazione Tecnica

## Architettura dell'Applicazione

### Struttura dei File
```
Universal-Compression-Tool/
├── src/                          # Codice sorgente C++
│   ├── universal_compressor.h/.cpp   # Classe principale
│   ├── cso_compressor.h/.cpp         # Compressore CSO standalone
│   ├── chd_compressor.h/.cpp         # Compressore CHD standalone
│   └── main.cpp                      # CLI unificata
├── bin/                          # Eseguibili compilati
│   └── universal-compressor.exe      # Tool nativo compilato
├── gui/                          # Interfaccia grafica
│   ├── main.py                       # GUI Python + Tkinter
│   ├── config.json                   # Configurazione GUI
│   └── README.md                     # Documentazione GUI
├── obj/                          # File oggetto
├── Makefile                      # Build system multipiattaforma
├── build_cpp.bat                # Script build Windows (generico)
├── quick_build.bat              # Script build Windows (MSYS2)
├── launch_gui.bat               # Avvio GUI
├── setup_dev_env.bat            # Setup ambiente sviluppo
├── README.md                     # Documentazione utente
├── TECHNICAL.md                  # Documentazione tecnica
└── PROJECT_STATUS.md             # Stato del progetto
```

### Componenti Principali (Versione C++)

#### 1. universal_compressor.h/.cpp
La classe principale che fornisce:
- Interfaccia unificata per CSO e CHD
- Gestione configurazioni
- Callback per progresso ed errori
- Validazione input/output
- API pubblica consistente

#### 2. cso_compressor.h/.cpp
Implementazione standalone del compressore CSO:
- Supporto formati: CSO1, CSO2, ZSO, DAX
- Algoritmi: Zlib, 7-Zip, LZ4, Libdeflate
- Compressione multi-thread
- Ottimizzazioni per velocità/qualità

#### 3. chd_compressor.h/.cpp
Implementazione standalone del compressore CHD:
- Formato CHD v5 compatibile MAME
- Codec: CDLZ, CDZL, CDFL
- Supporto metadata CD/DVD
- Gestione track e TOC

#### 4. main.cpp
CLI unificata che fornisce:
- Parsing argomenti completo
- Help integrato
- Configurazione flessibile
- Supporto batch processing

## Funzionalità Implementate

### Compressione CSO
- **Tool nativo**: universal-compressor.exe
- **Formati supportati**: CSO1, CSO2, ZSO, DAX
- **Opzioni configurabili**:
  - Numero di thread (1-16)
  - Formato di output
  - Dimensione blocco
  - Algoritmi di compressione (Zlib, 7-Zip, Zopfli)
  - Modalità veloce

### Compressione CHD
- **Tool nativo**: universal-compressor.exe
- **Formato supportato**: CHD (Compressed Hunks of Data)
- **Opzioni configurabili**:
  - Codec di compressione (cdlz, cdzl, cdfl)
  - Dimensione hunk
  - Numero di processori
  - Forzatura sovrascrittura

## Configurazione

Il tool supporta configurazione tramite parametri CLI. Vedere `universal-compressor.exe --help` per tutte le opzioni disponibili.

## Comandi Supportati

### Per CSO 
```bash
universal-compressor.exe --type=cso "input.iso" -o "output.cso" [opzioni]
```

### Per CHD
```bash
universal-compressor.exe --type=chd "input.iso" -o "output.chd" [opzioni]
```

Usare `--help` per vedere tutte le opzioni disponibili.

## Flusso di Lavoro

### 1. Inizializzazione
1. Caricamento librerie di compressione
2. Parsing argomenti CLI
3. Validazione parametri

### 2. Processo di Compressione
1. Validazione file input
2. Selezione algoritmo di compressione
3. Esecuzione compressione con callback progresso
4. Calcolo statistiche e cleanup

### 3. Completamento
1. Riepilogo risultati
2. Gestione errori se presenti

## Gestione Errori

### Errori Comuni
- **File mancanti**: Controllo esistenza file input
- **Permessi**: Verifica accesso scrittura cartella output
- **Spazio disco**: Monitoraggio spazio disponibile
- **File corrotti**: Validazione file ISO

### Logging
- Output verboso tramite flag --verbose
- Calcolo rapporti di compressione
- Tracking tempi di elaborazione

## Estensibilità

### Aggiunta Nuovi Formati
1. Aggiungere nuovo compressore in src/
2. Implementare interfaccia comune
3. Integrare in universal_compressor.cpp

### Miglioramenti Futuri
- Compressione parallela multipli file
- Supporto formati aggiuntivi (7z, ZIP)
- Drag & drop nella GUI
- Anteprima dimensioni compresse
- Temi e personalizzazione GUI
- Scheduler per compressioni automatiche

## Build e Distribuzione

### Requisiti Build
- MinGW-w64 GCC
- Make utility
- Librerie: zlib, lz4

### Requisiti GUI
- Python 3.7+ (con tkinter)

### Processo Build
1. Backend: Eseguire `make` o `build_cpp.bat`
2. GUI: Avviare con `launch_gui.bat` o `python gui\main.py`
3. Testare con file ISO di esempio

### Distribuzione
- File .exe nativo + librerie DLL
- GUI Python standalone (nessuna dipendenza aggiuntiva)
- Documentazione utente (README.md)

## Performance

### Ottimizzazioni Implementate
- Elaborazione asincrona processi
- Validazione input anticipata

### Considerazioni Performance
- CSO: Più veloce, minor compressione
- CHD: Più lento, maggior compressione
- Thread multipli migliorano prestazioni I/O

## Compatibilità

### Sistemi Supportati
- Windows 7/8/10/11 (x86/x64)
- Requisiti memoria: 512MB+
- Spazio disco: 100MB+ temporaneo

### Emulatori Compatibili
- **CSO**: PPSSPP, PCSX2, altri emulatori PSP/PS2
- **CHD**: MAME, Retroarch, altri emulatori arcade

---

**Versione documento**: 1.0  
**Data ultimo aggiornamento**: Giugno 2025  
**Autore**: Universal Compression Tool Development Team
