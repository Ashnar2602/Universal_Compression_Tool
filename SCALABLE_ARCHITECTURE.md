# Universal ISO Compression Tool - GUI Scalabile

## Panoramica

La GUI potenziata del Universal ISO Compression Tool è stata progettata con un'architettura modulare e scalabile che consente l'aggiunta facile di nuovi formati di compressione e codec senza modificare il codice principale.

## Architettura Scalabile

### 1. Sistema di Registrazione Formati

```autohotkey
; Registrazione di un nuovo formato
RegisterCompressionFormat("NEW_FORMAT", {
    name: "NEW_FORMAT",
    displayName: "🎯 Nuovo Formato - Descrizione",
    description: "Descrizione dettagliata del formato",
    cliParam: "new_format",
    inputExts: ["iso", "bin"],
    outputExts: ["new"],
    defaultOutputExt: "new",
    category: "Custom",
    priority: 10,
    
    options: {
        // Opzioni personalizzate
    }
})
```

### 2. Tipi di Opzioni Supportati

#### Dropdown
```autohotkey
algorithm: {
    name: "algorithm",
    displayName: "Algorithm",
    description: "Compression algorithm",
    type: "dropdown",
    values: ["LZMA", "LZMA2", "BZIP2"],
    descriptions: ["LZMA (Best)", "LZMA2 (Fast)", "BZIP2 (Good)"],
    default: "LZMA2",
    cliParam: "--algorithm"
}
```

#### Slider
```autohotkey
level: {
    name: "level",
    displayName: "Compression Level",
    description: "Compression level (1-9)",
    type: "slider",
    min: 1, max: 9, default: 5,
    cliParam: "--level"
}
```

#### Checkbox
```autohotkey
multithread: {
    name: "multithread",
    displayName: "Multi-threading",
    description: "Enable multi-threaded compression",
    type: "checkbox",
    default: true,
    cliParam: "--multithread"
}
```

#### Edit Box
```autohotkey
customParam: {
    name: "customParam",
    displayName: "Custom Parameter",
    description: "Custom compression parameter",
    type: "edit",
    default: "default_value",
    cliParam: "--custom"
}
```

### 3. Sistema di Job Processing

Il sistema di job processing è completamente scalabile e gestisce:

- **Job Queue**: Coda prioritaria con elaborazione asincrona
- **Concurrent Processing**: Supporto per più job simultanei
- **Progress Tracking**: Monitoraggio in tempo reale del progresso
- **Error Handling**: Gestione robusta degli errori
- **Statistics**: Raccolta automatica delle statistiche

## Funzionalità Principali

### Interface Dinamica

- **Format Selection**: Dropdown dinamico basato sui formati registrati
- **Options Panel**: Creazione automatica dei controlli basata sui metadata del formato
- **File Management**: Supporto drag & drop e selezione multipla
- **Progress Monitoring**: Barre di progresso per job individuali e generali

### Menu System Completo

- **File**: Gestione sessioni, import/export configurazioni
- **Edit**: Operazioni sui file (add, remove, select all)
- **Tools**: Queue manager, statistics, presets
- **Options**: Configurazioni globali e preferenze
- **Help**: Documentazione e supporto

### Gestione Avanzata

- **Concurrent Jobs**: Configurabile numero di job simultanei
- **Session Management**: Salvataggio/caricamento sessioni di lavoro
- **Preset System**: Configurazioni predefinite per diversi scenari
- **Statistics Tracking**: Raccolta dettagliata delle metriche

## Esempi di Estensione

### Aggiungere Supporto per 7-Zip

```autohotkey
RegisterCompressionFormat("7ZIP", {
    name: "7ZIP",
    displayName: "📦 7-Zip Archive",
    description: "Universal archive format with multiple algorithms",
    cliParam: "7zip",
    inputExts: ["iso", "bin", "img"],
    outputExts: ["7z"],
    defaultOutputExt: "7z",
    category: "Archive",
    priority: 3,
    
    options: {
        method: {
            name: "method",
            displayName: "Compression Method",
            type: "dropdown",
            values: ["LZMA2", "LZMA", "BZIP2", "DEFLATE"],
            default: "LZMA2",
            cliParam: "--7zip-method"
        },
        level: {
            name: "level",
            displayName: "Compression Level",
            type: "slider",
            min: 0, max: 9, default: 5,
            cliParam: "--7zip-level"
        },
        solid: {
            name: "solid",
            displayName: "Solid Archive",
            type: "checkbox",
            default: true,
            cliParam: "--7zip-solid"
        }
    }
})
```

### Aggiungere Supporto per ZSTD

```autohotkey
RegisterCompressionFormat("ZSTD", {
    name: "ZSTD",
    displayName: "⚡ Zstandard Compression",
    description: "Fast modern compression with excellent ratio",
    cliParam: "zstd",
    inputExts: ["iso", "bin", "img"],
    outputExts: ["zst"],
    defaultOutputExt: "zst",
    category: "Modern",
    priority: 4,
    
    options: {
        level: {
            name: "level",
            displayName: "Compression Level",
            type: "slider",
            min: 1, max: 22, default: 3,
            cliParam: "--zstd-level"
        },
        workers: {
            name: "workers",
            displayName: "Worker Threads",
            type: "slider",
            min: 1, max: 16, default: 4,
            cliParam: "--zstd-workers"
        },
        longRange: {
            name: "longRange",
            displayName: "Long Range Mode",
            type: "checkbox",
            default: false,
            cliParam: "--zstd-long"
        }
    }
})
```

## Backend Integration

### CLI Command Building

Il sistema costruisce automaticamente i comandi CLI basandosi sui metadata del formato:

```autohotkey
command := BuildCLICommand(formatKey, inputFile, outputFile, options)
; Esempio output: "universal-compressor.exe --type=zstd --zstd-level=5 --zstd-workers=4 input.iso output.zst"
```

### Option Validation

Sistema di validazione automatica delle opzioni:

```autohotkey
result := ValidateFormatOptions(formatKey, options)
if (!result.valid) {
    MsgBox, Error: %result.error%
}
```

## Plugin System (Futuro)

L'architettura supporta un sistema di plugin per caricare formati esterni:

```
plugins/
├── custom_format.ahk      # Definizione formato personalizzato
├── enterprise_codecs.ahk  # Codec aziendali
└── experimental.ahk       # Formati sperimentali
```

## Best Practices per l'Estensione

### 1. Naming Convention
- Nomi formati: MAIUSCOLO (es. "CSO", "CHD", "7ZIP")
- Nomi opzioni: camelCase (es. "compressionLevel", "useMultithread")
- CLI parameters: kebab-case con prefisso (es. "--cso-format", "--chd-hunk")

### 2. Metadata Completi
- Sempre fornire `description` dettagliata
- Specificare `category` per raggruppamento logico
- Impostare `priority` per ordinamento
- Includere `inputExts` e `outputExts` completi

### 3. Opzioni User-Friendly
- Usare `descriptions` per le dropdown
- Impostare `min`, `max` appropriati per slider
- Fornire valori `default` sensati
- Usare `inverted` per checkbox che disabilitano funzionalità

### 4. Testing
- Testare con file di diverse dimensioni
- Verificare gestione errori
- Controllare integrazione con job queue
- Validare output CLI commands

## File di Configurazione

### Structure
```ini
[General]
OutputFolder=C:\Compressed
CurrentFormat=CSO
VerboseMode=0
DeleteInput=0

[CSO]
format=cso1
threads=4
fastMode=0
useZlib=1
use7zip=1

[CHD]
hunkSize=19584
processors=4
compression=cdlz,cdzl,cdfl
force=1
```

## Statistiche e Monitoring

Il sistema raccoglie automaticamente:
- Numero totale job processati
- Rapporti di compressione
- Tempi di elaborazione
- Dimensioni input/output
- Tasso di successo/fallimento

## Roadmap Futura

### Prossime Funzionalità
1. **Drag & Drop**: Supporto nativo per trascinamento file
2. **Batch Presets**: Configurazioni predefinite per scenari comuni
3. **Network Compression**: Supporto per compressione remota
4. **Real-time Preview**: Anteprima dimensioni compresse
5. **Advanced Scheduling**: Pianificazione job automatici

### Nuovi Formati Candidati
- **RAR**: Archivi WinRAR con recovery
- **BROTLI**: Compressione web moderna
- **XZ**: Compressione LZMA high-ratio
- **TAR.GZ**: Archivi Unix/Linux
- **VMDK**: Dischi virtuali VMware

---

Questa architettura scalabile garantisce che il tool possa crescere facilmente aggiungendo nuovi formati e funzionalità senza riscrivere il codice esistente, mantenendo sempre la compatibilità e l'usabilità.
