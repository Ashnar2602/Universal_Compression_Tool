; ========================================
; COMPRESSION FORMAT REGISTRY
; Sistema scalabile per futuri formati
; ========================================

; Esempio di come aggiungere un nuovo formato in futuro:

; 7ZIP Format (Esempio futuro)
RegisterCompressionFormat("7ZIP", {
    name: "7ZIP",
    displayName: "📦 7ZIP - Universal Archive Format",
    description: "Multi-platform archive format with excellent compression ratio. Supports multiple compression algorithms.",
    cliParam: "7zip",
    inputExts: ["iso", "bin", "img", "cue", "nrg", "mdf"],
    outputExts: ["7z"],
    defaultOutputExt: "7z",
    category: "Archive",
    priority: 3,
    
    options: {
        compressionLevel: {
            name: "compressionLevel",
            displayName: "Compression Level",
            description: "Compression level from 0 (store) to 9 (ultra)",
            type: "slider",
            min: 0, max: 9, default: 5,
            cliParam: "--7zip-level"
        },
        algorithm: {
            name: "algorithm", 
            displayName: "Algorithm",
            description: "Compression algorithm",
            type: "dropdown",
            values: ["LZMA", "LZMA2", "BZIP2", "DEFLATE"],
            descriptions: ["LZMA (Best ratio)", "LZMA2 (Multi-core)", "BZIP2 (Good ratio)", "DEFLATE (Fast)"],
            default: "LZMA2",
            cliParam: "--7zip-algorithm"
        },
        solidArchive: {
            name: "solidArchive",
            displayName: "Solid Archive",
            description: "Create solid archive for better compression",
            type: "checkbox",
            default: true,
            cliParam: "--7zip-solid"
        },
        multithread: {
            name: "multithread",
            displayName: "Multi-threading",
            description: "Enable multi-threaded compression",
            type: "checkbox",
            default: true,
            cliParam: "--7zip-mt"
        }
    }
})

; RAR Format (Esempio futuro)
RegisterCompressionFormat("RAR", {
    name: "RAR",
    displayName: "📚 RAR - High Compression Archive",
    description: "Proprietary archive format with excellent compression ratio and error recovery features.",
    cliParam: "rar",
    inputExts: ["iso", "bin", "img", "cue", "nrg"],
    outputExts: ["rar"],
    defaultOutputExt: "rar",
    category: "Archive",
    priority: 4,
    
    options: {
        compressionMethod: {
            name: "compressionMethod",
            displayName: "Compression Method",
            description: "RAR compression method",
            type: "dropdown",
            values: ["m0", "m1", "m2", "m3", "m4", "m5"],
            descriptions: ["Store", "Fastest", "Fast", "Normal", "Good", "Best"],
            default: "m3",
            cliParam: "--rar-method"
        },
        recovery: {
            name: "recovery",
            displayName: "Recovery Record",
            description: "Add recovery record for error correction",
            type: "checkbox",
            default: true,
            cliParam: "--rar-recovery"
        },
        volumeSize: {
            name: "volumeSize",
            displayName: "Volume Size (MB)",
            description: "Split archive into volumes of specified size (0 = no split)",
            type: "edit",
            default: "0",
            cliParam: "--rar-volume"
        }
    }
})

; ZSTD Format (Esempio futuro - compressione moderna)
RegisterCompressionFormat("ZSTD", {
    name: "ZSTD",
    displayName: "⚡ ZSTD - Fast Modern Compression",
    description: "Facebook's Zstandard compression algorithm. Excellent balance between speed and compression ratio.",
    cliParam: "zstd",
    inputExts: ["iso", "bin", "img", "cue"],
    outputExts: ["zst"],
    defaultOutputExt: "zst",
    category: "Modern",
    priority: 5,
    
    options: {
        level: {
            name: "level",
            displayName: "Compression Level",
            description: "Compression level (1=fast, 22=best)",
            type: "slider",
            min: 1, max: 22, default: 3,
            cliParam: "--zstd-level"
        },
        threads: {
            name: "threads",
            displayName: "Threads",
            description: "Number of compression threads",
            type: "slider",
            min: 1, max: 16, default: 4,
            cliParam: "--zstd-threads"
        },
        longRange: {
            name: "longRange",
            displayName: "Long Range Mode",
            description: "Enable long range mode for better compression",
            type: "checkbox",
            default: false,
            cliParam: "--zstd-long"
        }
    }
})

; ========================================
; SISTEMA CATEGORIZZAZIONE
; ========================================

GetFormatsByCategory() {
    global COMPRESSION_FORMATS
    
    categories := {}
    
    for formatKey, formatData in COMPRESSION_FORMATS {
        category := formatData.hasKey("category") ? formatData.category : "Other"
        
        if (!categories.hasKey(category)) {
            categories[category] := []
        }
        
        categories[category].Push(formatKey)
    }
    
    return categories
}

; ========================================
; SISTEMA VALIDAZIONE OPZIONI
; ========================================

ValidateFormatOptions(formatKey, options) {
    global COMPRESSION_FORMATS
    
    if (!COMPRESSION_FORMATS.hasKey(formatKey)) {
        return {valid: false, error: "Unknown format: " . formatKey}
    }
    
    formatData := COMPRESSION_FORMATS[formatKey]
    if (!formatData.hasKey("options")) {
        return {valid: true}  ; No options to validate
    }
    
    ; Validate each option
    for optionKey, optionValue in options {
        if (!formatData.options.hasKey(optionKey)) {
            return {valid: false, error: "Unknown option: " . optionKey . " for format: " . formatKey}
        }
        
        optionData := formatData.options[optionKey]
        
        ; Type-specific validation
        if (optionData.type == "slider") {
            if (optionValue < optionData.min || optionValue > optionData.max) {
                return {valid: false, error: optionKey . " must be between " . optionData.min . " and " . optionData.max}
            }
        } else if (optionData.type == "dropdown") {
            validValue := false
            for index, validOption in optionData.values {
                if (validOption == optionValue) {
                    validValue := true
                    break
                }
            }
            if (!validValue) {
                return {valid: false, error: "Invalid value for " . optionKey . ": " . optionValue}
            }
        }
    }
    
    return {valid: true}
}

; ========================================
; SISTEMA CLI COMMAND BUILDER
; ========================================

BuildCLICommand(formatKey, inputFile, outputFile, options) {
    global COMPRESSION_FORMATS, CLI_EXECUTABLE
    
    if (!COMPRESSION_FORMATS.hasKey(formatKey)) {
        return ""
    }
    
    formatData := COMPRESSION_FORMATS[formatKey]
    
    ; Base command
    command := """" . CLI_EXECUTABLE . """ --type=" . formatData.cliParam . " --output=""" . outputFile . """ """ . inputFile . """"
    
    ; Add options
    if (formatData.hasKey("options")) {
        for optionKey, optionValue in options {
            if (formatData.options.hasKey(optionKey)) {
                optionData := formatData.options[optionKey]
                
                if (optionData.type == "checkbox") {
                    if (optionData.hasKey("inverted") && optionData.inverted) {
                        ; Inverted checkbox - add param only if false
                        if (!optionValue) {
                            command .= " " . optionData.cliParam
                        }
                    } else {
                        ; Normal checkbox - add param only if true
                        if (optionValue) {
                            command .= " " . optionData.cliParam
                        }
                    }
                } else {
                    ; Value-based option
                    command .= " " . optionData.cliParam . "=" . optionValue
                }
            }
        }
    }
    
    return command
}

; ========================================
; SISTEMA ESTENSIONI DINAMICHE
; ========================================

GetAllSupportedExtensions() {
    global COMPRESSION_FORMATS
    
    allExtensions := []
    
    for formatKey, formatData in COMPRESSION_FORMATS {
        for index, ext in formatData.inputExts {
            ; Add if not already present
            found := false
            for existingIndex, existingExt in allExtensions {
                if (existingExt == ext) {
                    found := true
                    break
                }
            }
            if (!found) {
                allExtensions.Push(ext)
            }
        }
    }
    
    return allExtensions
}

BuildFileDialog() {
    allExtensions := GetAllSupportedExtensions()
    
    ; Build filter string
    filterString := "All Supported ("
    for index, ext in allExtensions {
        filterString .= "*." . ext . ";"
    }
    filterString := RTrim(filterString, ";") . ")|"
    
    for index, ext in allExtensions {
        filterString .= "*." . ext . ";"
    }
    filterString := RTrim(filterString, ";")
    
    ; Add individual format filters
    global COMPRESSION_FORMATS
    for formatKey, formatData in COMPRESSION_FORMATS {
        filterString .= "|" . formatData.name . " Files ("
        for index, ext in formatData.inputExts {
            filterString .= "*." . ext . ";"
        }
        filterString := RTrim(filterString, ";") . ")|"
        
        for index, ext in formatData.inputExts {
            filterString .= "*." . ext . ";"
        }
        filterString := RTrim(filterString, ";")
    }
    
    return filterString
}

; ========================================
; SISTEMA PRESET CONFIGURAZIONI
; ========================================

GetPresetConfigurations() {
    return {
        fast: {
            name: "Fast Compression",
            description: "Optimized for speed",
            icon: "⚡"
        },
        balanced: {
            name: "Balanced",
            description: "Good balance of speed and size",
            icon: "⚖️"
        },
        best: {
            name: "Best Compression",
            description: "Maximum compression ratio",
            icon: "🎯"
        },
        custom: {
            name: "Custom",
            description: "User-defined settings",
            icon: "⚙️"
        }
    }
}

ApplyPresetToFormat(formatKey, presetKey) {
    global COMPRESSION_FORMATS
    
    if (!COMPRESSION_FORMATS.hasKey(formatKey)) {
        return {}
    }
    
    formatData := COMPRESSION_FORMATS[formatKey]
    presetOptions := {}
    
    ; Apply preset based on format and preset type
    if (formatKey == "CSO") {
        if (presetKey == "fast") {
            presetOptions := {format: "zso", threads: 8, fastMode: true, useZlib: true, use7zip: false}
        } else if (presetKey == "balanced") {
            presetOptions := {format: "cso1", threads: 4, fastMode: false, useZlib: true, use7zip: true}
        } else if (presetKey == "best") {
            presetOptions := {format: "dax", threads: 2, fastMode: false, useZlib: true, use7zip: true}
        }
    } else if (formatKey == "CHD") {
        if (presetKey == "fast") {
            presetOptions := {hunkSize: "32768", processors: 8, compression: "cdfl", force: true}
        } else if (presetKey == "balanced") {
            presetOptions := {hunkSize: "19584", processors: 4, compression: "cdlz,cdzl", force: true}
        } else if (presetKey == "best") {
            presetOptions := {hunkSize: "8192", processors: 2, compression: "cdlz,cdzl,cdfl", force: true}
        }
    }
    
    return presetOptions
}

; ========================================
; SISTEMA LOGGING E DEBUG
; ========================================

LogFormatOperation(formatKey, operation, details := "") {
    timestamp := A_Now
    FormatTime, formattedTime, %timestamp%, yyyy-MM-dd HH:mm:ss
    
    logEntry := formattedTime . " [" . formatKey . "] " . operation
    if (details != "") {
        logEntry .= " - " . details
    }
    
    ; Write to debug output
    OutputDebug, %logEntry%
    
    ; Could also write to file for production logging
    ; FileAppend, %logEntry%`n, compression_log.txt
}

; ========================================
; ESEMPI DI UTILIZZO PER SVILUPPATORI
; ========================================

/*
Esempio 1: Registrare un nuovo formato

RegisterCompressionFormat("BZIP2", {
    name: "BZIP2",
    displayName: "📦 BZIP2 - High Compression",
    description: "BZIP2 compression with excellent ratio",
    cliParam: "bzip2",
    inputExts: ["iso", "bin"],
    outputExts: ["bz2"],
    defaultOutputExt: "bz2",
    category: "Archive",
    priority: 6,
    
    options: {
        blockSize: {
            name: "blockSize",
            displayName: "Block Size",
            description: "Compression block size",
            type: "dropdown",
            values: ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
            descriptions: ["100KB", "200KB", "300KB", "400KB", "500KB", "600KB", "700KB", "800KB", "900KB"],
            default: "9",
            cliParam: "--bzip2-block"
        }
    }
})

Esempio 2: Validare opzioni

options := {blockSize: "9", invalidOption: "test"}
result := ValidateFormatOptions("BZIP2", options)
if (!result.valid) {
    MsgBox, Error: %result.error%
}

Esempio 3: Costruire comando CLI

command := BuildCLICommand("BZIP2", "input.iso", "output.bz2", {blockSize: "9"})
; Risultato: "cli.exe --type=bzip2 --output="output.bz2" "input.iso" --bzip2-block=9"

Esempio 4: Ottenere formati per categoria

categories := GetFormatsByCategory()
for categoryName, formatList in categories {
    ; categoryName = "Gaming", "Archive", etc.
    ; formatList = ["CSO", "CHD"] per Gaming
}
*/
