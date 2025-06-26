# Universal ISO Compression Tool - GUI

## Descrizione

GUI semplice e moderna per il Universal ISO Compression Tool, sviluppata in Python con Tkinter per la massima compatibilità e semplicità.

## Caratteristiche

### 🎯 **Interfaccia Intuitiva**
- Selezione file singoli o cartelle intere
- Anteprima dei file selezionati con dimensioni
- Configurazione semplice delle opzioni di compressione

### ⚙️ **Opzioni di Compressione**
- **Formati supportati**: CSO, CHD
- **Thread CPU**: Configurabile da 1 a 16 thread
- **File concorrenti**: Compressione parallela di più file (1-8)
- **Salvataggio configurazione**: Le impostazioni vengono salvate automaticamente

### 📊 **Monitoraggio Progresso**
- Barra di progresso generale
- Status in tempo reale per ogni file
- Gestione errori e interruzione processi

## Requisiti

- **Python 3.7+** (con tkinter incluso)
- **Windows 7/8/10/11**
- **Backend C++**: `universal-compressor.exe` compilato nella cartella `bin/`

## Installazione e Uso

### 1. Installazione Python
Se Python non è installato:
1. Scaricare da [python.org](https://python.org)
2. Durante l'installazione, selezionare "Add Python to PATH"
3. Verificare con `python --version` nel prompt dei comandi

### 2. Avvio della GUI
```batch
# Doppio click su:
launch_gui.bat

# Oppure da terminale:
python gui\main.py
```

### 3. Utilizzo
1. **Seleziona File**: Usa "Add Files..." o "Add Folder..." per aggiungere file ISO
2. **Cartella Output**: Seleziona dove salvare i file compressi
3. **Formato**: Scegli tra CSO (più veloce) e CHD (maggiore compressione)
4. **Thread**: Imposta il numero di thread CPU da utilizzare
5. **File Concorrenti**: Quanti file comprimere simultaneamente
6. **Avvia**: Clicca "Start Compression"

## Struttura File

```
gui/
├── main.py           # GUI principale
├── config.json       # Configurazione salvata
└── README.md         # Questa documentazione

launch_gui.bat        # Script di avvio Windows
```

## Configurazione

Le impostazioni vengono salvate automaticamente in `gui/config.json`:

```json
{
  "output_folder": "C:/Output",
  "format": "cso",
  "threads": 4,
  "concurrent_files": 1
}
```

## Funzionalità Avanzate

### Selezione File
- **File singoli**: Supporta ISO, BIN, IMG
- **Cartelle**: Scansione automatica di tutti i file compatibili
- **Lista files**: Visualizzazione nome, dimensione e stato

### Gestione Progresso
- **Tempo reale**: Aggiornamento continuo dello stato
- **Interruzione**: Possibilità di fermare il processo in qualsiasi momento
- **Gestione errori**: Notifica automatica in caso di problemi

### Ottimizzazioni
- **Threading**: Compressione in background per UI responsiva
- **Memoria**: Gestione efficiente della memoria per file grandi
- **Compatibilità**: Funziona su sistemi Windows legacy

## Troubleshooting

### Errori Comuni

**"Python is not installed"**
- Installare Python da python.org
- Verificare che sia aggiunto al PATH

**"tkinter is not available"**
- Reinstallare Python con supporto completo
- Su Linux: `sudo apt-get install python3-tk`

**"universal-compressor.exe not found"**
- Compilare il backend C++ con `build_cpp.bat`
- Verificare che l'eseguibile sia in `bin/universal-compressor.exe`

**GUI si blocca durante compressione**
- La GUI è progettata per rimanere responsiva
- Il progresso viene aggiornato automaticamente
- Usare il pulsante "Stop" per interrompere

### Performance

**Ottimizzazioni consigliate:**
- **Thread CPU**: Usa tutti i core disponibili (default: 4)
- **File concorrenti**: Inizia con 1, aumenta se hai molto spazio disco e RAM
- **Formato**: CSO per velocità, CHD per dimensioni minori

**Limitazioni:**
- La compressione simultanea di molti file richiede molta RAM
- File molto grandi (>4GB) potrebbero richiedere tempo
- Su sistemi più vecchi, usa meno thread

## Vantaggi vs AutoHotkey

### ✅ **Vantaggi della GUI Python**
- **Cross-platform**: Funziona su Windows, Linux, macOS
- **Più stabile**: Gestione errori robusta e thread-safe
- **Manutenibilità**: Codice chiaro e ben strutturato
- **Estensibilità**: Facile aggiungere nuove funzionalità
- **Performance**: Gestione efficiente della memoria e processi

### 🔧 **Funzionalità Future**
- Drag & drop dei file
- Anteprima dimensioni compresse
- Temi e personalizzazione
- Supporto per altri formati (7z, ZIP)
- Scheduler per compressioni automatiche
- Log dettagliati delle operazioni

## Sviluppo

Per modificare o estendere la GUI:

1. **Aggiungere nuove opzioni**: Modificare `create_options_section()`
2. **Cambiare layout**: Modificare i metodi `create_*_section()`
3. **Nuovi formati**: Estendere `build_compression_command()`
4. **Migliorare UI**: Aggiungere temi o widget personalizzati

Il codice è completamente commentato e modulare per facilitare le modifiche.

---

**Versione**: 1.0  
**Compatibilità**: Python 3.7+, Windows 7+  
**Licenza**: Come da progetto principale
