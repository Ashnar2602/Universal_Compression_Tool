# Universal ISO Compression Tool - Documentazione Tecnica

## Architettura dell'Applicazione

### Struttura dei File (Versione C++ Nativa)
```
Universal-Compression-Tool/
├── src/                          # Codice sorgente C++
│   ├── universal_compressor.h/.cpp   # Classe principale
│   ├── cso_compressor.h/.cpp         # Compressore CSO standalone
│   ├── chd_compressor.h/.cpp         # Compressore CHD standalone
│   └── main.cpp                      # CLI unificata
├── bin/                          # Eseguibili compilati
│   └── universal-compressor.exe      # Tool nativo compilato
├── obj/                          # File oggetto
├── Makefile                      # Build system multipiattaforma
├── build_cpp.bat                # Script build Windows (generico)
├── quick_build.bat              # Script build Windows (MSYS2)
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
- **Eseguibile**: maxcso.exe
- **Formati supportati**: CSO1, CSO2, ZSO, DAX
- **Opzioni configurabili**:
  - Numero di thread (1-16)
  - Formato di output
  - Dimensione blocco
  - Algoritmi di compressione (Zlib, 7-Zip, Zopfli)
  - Modalità veloce

### Compressione CHD
- **Eseguibile**: chdman.exe
- **Formato supportato**: CHD (Compressed Hunks of Data)
- **Opzioni configurabili**:
  - Codec di compressione (cdlz, cdzl, cdfl)
  - Dimensione hunk
  - Numero di processori
  - Forzatura sovrascrittura

### Interfaccia Utente
- **Selezione tipo compressione**: Radio button per CSO/CHD
- **Gestione file**:
  - Selezione multipla file ISO
  - Lista file con stato avanzamento
  - Selezione cartella output
- **Opzioni avanzate**: Finestra separata per configurazioni dettagliate
- **Monitoraggio**: Barra di stato con progresso e statistiche

## Configurazione

### File Settings.ini
Struttura del file di configurazione:

```ini
[General]
OutputFolder=          # Cartella di output
CompressionType=CSO    # Tipo compressione (CSO/CHD)
RemoveInputFiles=no    # Rimozione file input
ForceOverwrite=yes     # Forza sovrascrittura
ShowConsole=no         # Mostra console debug

[CSO]
Threads=4              # Numero thread
Format=cso1            # Formato output
BlockSize=             # Dimensione blocco (auto se vuoto)
UseZlib=yes           # Usa compressione Zlib
Use7zip=yes           # Usa compressione 7-Zip
FastMode=no           # Modalità veloce

[CHD]
Compression=cdlz,cdzl,cdfl  # Codec compressione
HunkSize=19584              # Dimensione hunk
NumProcessors=4             # Numero processori
Force=yes                   # Forza operazione

[Window]
MainX=                 # Posizione finestra X
MainY=                 # Posizione finestra Y
MainWidth=600          # Larghezza finestra
MainHeight=500         # Altezza finestra

[Advanced]
ShowVerboseOutput=no   # Output verboso
PlaySoundOnComplete=no # Suono completamento
```

## Comandi Generati

### Per CSO (maxcso.exe)
```bash
maxcso.exe "input.iso" -o "output.cso" [opzioni]
```

Opzioni principali:
- `--threads=N`: Numero thread
- `--format=FORMAT`: Formato output (cso1, cso2, zso, dax)
- `--block=SIZE`: Dimensione blocco
- `--use-zlib`: Abilita Zlib
- `--use-7zdeflate`: Abilita 7-Zip deflate
- `--fast`: Modalità veloce

### Per CHD (chdman.exe)
```bash
chdman.exe createcd -i "input.iso" -o "output.chd" [opzioni]
```

Opzioni principali:
- `-f`: Forza sovrascrittura
- `-c "CODECS"`: Codec compressione
- `-hs SIZE`: Dimensione hunk
- `-np N`: Numero processori

## Flusso di Lavoro

### 1. Inizializzazione
1. Controllo esistenza eseguibili (maxcso.exe, chdman.exe)
2. Caricamento impostazioni da Settings.ini
3. Creazione interfaccia grafica
4. Inizializzazione variabili globali

### 2. Selezione File
1. Apertura dialog selezione multipla file
2. Validazione estensioni supportate (.iso, .bin, .img)
3. Aggiunta alla lista con calcolo dimensioni
4. Aggiornamento interfaccia

### 3. Configurazione
1. Selezione tipo compressione (CSO/CHD)
2. Impostazione cartella output
3. Configurazione opzioni base/avanzate
4. Validazione parametri

### 4. Processo di Compressione
1. Validazione input (file, cartella output)
2. Generazione comandi per ogni file
3. Esecuzione sequenziale processi
4. Monitoraggio progresso e aggiornamento stato
5. Calcolo statistiche compressione
6. Gestione errori e cleanup

### 5. Completamento
1. Riepilogo risultati
2. Notifica sonora (opzionale)
3. Rimozione file input (opzionale)
4. Salvataggio impostazioni

## Gestione Errori

### Errori Comuni
- **File mancanti**: Controllo esistenza maxcso.exe/chdman.exe
- **Permessi**: Verifica accesso scrittura cartella output
- **Spazio disco**: Monitoraggio spazio disponibile
- **File corrotti**: Validazione file ISO

### Logging
- Aggiornamenti stato nella status bar
- Output comando in modalità verbosa
- Calcolo rapporti di compressione
- Tracking tempi di elaborazione

## Estensibilità

### Aggiunta Nuovi Formati
1. Aggiungere nuovo tipo in `GUI.compressionTypes`
2. Implementare funzione compressione specifica
3. Aggiungere opzioni configurazione in Settings.ini
4. Estendere GUI opzioni avanzate

### Miglioramenti Futuri
- Compressione parallela multipli file
- Interfaccia drag & drop
- Anteprima dimensioni file compressi
- Integrazione con altri tool compressione
- Supporto formati aggiuntivi (7z, ZIP)
- Scheduler per compressioni automatiche

## Build e Distribuzione

### Requisiti Build
- AutoHotkey v1.1+
- Ahk2Exe.exe (compiler)
- maxcso.exe (ultima versione)
- chdman.exe (compatibile MAME)

### Processo Build
1. Eseguire `Build.bat`
2. Copiare eseguibili richiesti
3. Testare con `Setup.bat`
4. Creare pacchetto distribuzione

### Distribuzione
- File .exe compilato + dipendenze
- Documentazione utente (README.md)
- Script setup automatico
- File configurazione default

## Performance

### Ottimizzazioni Implementate
- Elaborazione asincrona processi
- Calcolo dimensioni file on-demand
- Caching configurazioni
- Validazione input anticipata

### Considerazioni Performance
- CSO: Più veloce, minor compressione
- CHD: Più lento, maggior compressione
- Thread multipli migliorano prestazioni I/O
- Dimensioni blocco influenzano velocità/qualità

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
