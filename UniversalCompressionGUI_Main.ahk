; ========================================
; UNIVERSAL ISO COMPRESSION TOOL - GUI PRINCIPALE
; Architettura scalabile per supporto multipli formati
; ========================================

#SingleInstance Force
#NoEnv
#Persistent
DetectHiddenWindows On
SetTitleMatchMode 3
SetWorkingDir %A_ScriptDir%

; Include moduli (utilizzano i file esistenti da namDHC)
#Include ClassImageButton.ahk
#Include ConsoleClass.ahk  
#Include JSON.ahk
#Include SelectFolderEx.ahk

; Include le nostre estensioni
#Include UniversalCompressionGUI_Extensions.ahk

; ========================================
; CONFIGURAZIONE E COSTANTI
; ========================================

APP_NAME := "Universal ISO Compression Tool"
APP_VERSION := "2.0.0-GUI"
APP_MAIN_NAME := APP_NAME " v" APP_VERSION
CLI_EXECUTABLE := "bin\universal-compressor.exe"

; Variabili globali per job processing
CURRENT_JOB_INDEX := 0
TOTAL_JOBS := 0
JOBS_COMPLETED := 0
JOBS_FAILED := 0
ASYNC_COMMAND := ""
ASYNC_CALLBACK := ""

; ========================================
; CONFIGURAZIONE FORMATI - ARCHITETTURA ESTENSIBILE
; ========================================

; Ogni formato è completamente auto-contenuto e facilmente aggiungibile
COMPRESSION_FORMATS := {}

; === FORMATO CSO ===
COMPRESSION_FORMATS.CSO := {
    name: "CSO",
    displayName: "CSO - Compressed ISO for PSP/PS2",
    description: "Optimized for PSP and PS2 emulators like PPSSPP and PCSX2",
    cliParam: "cso",
    inputExts: ["iso", "bin", "img"],
    outputExts: ["cso", "cso2", "zso", "dax"], 
    defaultOutputExt: "cso",
    icon: "🎮",
    
    options: {
        format: {
            name: "format",
            displayName: "Output Format",
            description: "Choose compression format variant",
            type: "dropdown",
            values: ["cso1", "cso2", "zso", "dax"],
            descriptions: ["CSO v1 (Standard)", "CSO v2 (Improved)", "ZSO (Fast)", "DAX (Best compression)"],
            default: "cso1",
            cliParam: "--cso-format"
        },
        threads: {
            name: "threads",
            displayName: "Threads",
            description: "Number of compression threads (more = faster on multi-core)",
            type: "slider",
            min: 1, max: 16, default: 4,
            cliParam: "--cso-threads"
        },
        blockSize: {
            name: "blockSize", 
            displayName: "Block Size",
            description: "Compression block size in bytes (0 = automatic)",
            type: "edit",
            default: "0",
            cliParam: "--cso-block"
        },
        fastMode: {
            name: "fastMode",
            displayName: "Fast Mode",
            description: "Prioritize speed over compression ratio",
            type: "checkbox",
            default: false,
            cliParam: "--cso-fast"
        },
        useZlib: {
            name: "useZlib",
            displayName: "Enable Zlib",
            description: "Use Zlib compression algorithm",
            type: "checkbox",
            default: true,
            cliParam: "--cso-no-zlib",
            inverted: true
        },
        use7zip: {
            name: "use7zip", 
            displayName: "Enable 7-Zip",
            description: "Use 7-Zip compression algorithm",
            type: "checkbox",
            default: true,
            cliParam: "--cso-no-7zip", 
            inverted: true
        }
    }
}

; === FORMATO CHD ===
COMPRESSION_FORMATS.CHD := {
    name: "CHD",
    displayName: "CHD - Compressed Hunks of Data",
    description: "MAME arcade and console disc format with excellent compression",
    cliParam: "chd",
    inputExts: ["iso", "bin", "img", "cue"],
    outputExts: ["chd"],
    defaultOutputExt: "chd", 
    icon: "🕹️",
    
    options: {
        hunkSize: {
            name: "hunkSize",
            displayName: "Hunk Size", 
            description: "Size of compression hunks in bytes",
            type: "edit",
            default: "19584",
            cliParam: "--chd-hunk"
        },
        processors: {
            name: "processors",
            displayName: "Processors",
            description: "Number of CPU cores to use",
            type: "slider",
            min: 1, max: 16, default: 4,
            cliParam: "--chd-processors"
        },
        compression: {
            name: "compression",
            displayName: "Compression Codecs",
            description: "Comma-separated list of compression codecs",
            type: "edit", 
            default: "cdlz,cdzl,cdfl",
            cliParam: "--chd-compression"
        },
        force: {
            name: "force",
            displayName: "Force Overwrite",
            description: "Overwrite existing output files",
            type: "checkbox",
            default: true,
            cliParam: "--chd-no-force",
            inverted: true
        }
    }
}

; ========================================
; PLACEHOLDER PER FUTURI FORMATI
; ========================================

; Esempio di come aggiungere formato 7-Zip in futuro:
/*
COMPRESSION_FORMATS.SEVENZ := {
    name: "7Z", 
    displayName: "7Z - 7-Zip Archive",
    description: "Universal archive format with excellent compression",
    cliParam: "7z",
    inputExts: ["iso", "bin", "img", "cue"],
    outputExts: ["7z"],
    defaultOutputExt: "7z",
    icon: "📦",
    
    options: {
        level: {
            name: "level",
            displayName: "Compression Level",
            description: "Compression level (0=fast, 9=best)",
            type: "slider",
            min: 0, max: 9, default: 5,
            cliParam: "--7z-level"
        },
        method: {
            name: "method",
            displayName: "Compression Method", 
            description: "Compression algorithm to use",
            type: "dropdown",
            values: ["LZMA", "LZMA2", "PPMd", "BZip2"],
            default: "LZMA2", 
            cliParam: "--7z-method"
        }
    }
}
*/

; ========================================
; CONFIGURAZIONE GUI AVANZATA
; ========================================

GUI := {}

; Tema colori moderno
GUI.colors := {
    background: 0xFFF5F5F5,
    primary: 0xFF2196F3,
    success: 0xFF4CAF50, 
    warning: 0xFFFF9800,
    danger: 0xFFF44336,
    text: 0xFF212121,
    textSecondary: 0xFF757575
}

; Stili bottoni professionali
GUI.buttons := {}
GUI.buttons.default := {
    normal: [0, 0xFFEEEEEE, "", 0xFF212121, 2],
    hover:  [0, 0xFFE0E0E0, "", 0xFF1976D2, 2], 
    clicked:[0, 0xFFD0D0D0, "", 0xFF0D47A1, 2],
    disabled:[0, 0xFFF5F5F5, "", 0xFFBDBDBD, 2]
}

GUI.buttons.primary := {
    normal: [0, 0xFF2196F3, "", "White", 3],
    hover:  [0, 0xFF1976D2, "", "White", 3],
    clicked:[0, 0xFF0D47A1, "", "White", 3], 
    disabled:[0, 0xFFBBBBBB, "", "White", 3]
}

GUI.buttons.success := {
    normal: [0, 0xFF4CAF50, "", "White", 3],
    hover:  [0, 0xFF45A049, "", "White", 3],
    clicked:[0, 0xFF3E8B41, "", "White", 3],
    disabled:[0, 0xFFBBBBBB, "", "White", 3]
}

GUI.buttons.danger := {
    normal: [0, 0xFFF44336, "", "White", 3],
    hover:  [0, 0xFFE53935, "", "White", 3], 
    clicked:[0, 0xFFD32F2F, "", "White", 3],
    disabled:[0, 0xFFBBBBBB, "", "White", 3]
}

; ========================================
; VARIABILI GLOBALI
; ========================================

CURRENT_FORMAT := "CSO"
INPUT_FILES := []
OUTPUT_FOLDER := A_ScriptDir "\compressed"
SETTINGS_FILE := "UniversalCompressor.ini"
VERBOSE_MODE := false
DELETE_INPUT := false

; ========================================
; INIZIALIZZAZIONE APPLICAZIONE
; ========================================

LoadSettings()
CreateMainGUI()
CreateAdvancedMenus() 
RefreshGUI()

; Mostra messaggio benvenuto
SetTimer, ShowWelcomeMessage, -1000

return

; ========================================
; CREAZIONE GUI PRINCIPALE
; ========================================

CreateMainGUI() {
    global
    
    ; === CONFIGURAZIONE FINESTRA ===
    Gui, +Resize +MinSize800x600
    Gui, Color, % GUI.colors.background
    
    ; Status bar con parti multiple
    Gui, Add, StatusBar, , Ready
    SB_SetParts(200, 200, 200, -1)
    SB_SetText("Ready", 1)
    SB_SetText("Files: 0", 2) 
    SB_SetText("Format: " . CURRENT_FORMAT, 3)
    SB_SetText(APP_MAIN_NAME, 4)
    
    ; === HEADER CON LOGO E TITOLO ===
    Gui, Font, s16 Bold c0x2196F3
    Gui, Add, Text, x20 y15 w760 Center, %APP_NAME%
    Gui, Font, s9 Normal c0x757575
    Gui, Add, Text, x20 y45 w760 Center, Universal compression tool supporting multiple formats with scalable architecture
    
    ; === SEZIONE SELEZIONE FORMATO ===
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y70 w760 h90 Section, 🎯 Compression Format Selection
    
    Gui, Font, s9 Normal
    Gui, Add, Text, x35 y95, Choose compression format:
    
    ; Dropdown formati con descrizioni
    formatList := ""
    for formatKey, formatData in COMPRESSION_FORMATS {
        icon := formatData.icon ? formatData.icon . " " : ""
        formatList .= icon . formatData.displayName . "|"
    }
    formatList := RTrim(formatList, "|")
    
    Gui, Add, DropDownList, x35 y115 w400 vCompressionFormat gFormatChanged Choose1, %formatList%
    
    ; Descrizione formato selezionato
    Gui, Font, s8 c0x757575
    Gui, Add, Text, x35 y145 w600 h20 vFormatDescription, Loading format description...
    
    ; === SEZIONE INPUT FILES ===
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y175 w760 h220 Section, 📁 Input Files Management
    
    ; Toolbar file
    Gui, Font, s9 Normal
    Gui, Add, Button, x35 y200 w90 h32 gAddFiles hwndBtnAddFiles, 📄 Add Files
    Gui, Add, Button, x135 y200 w90 h32 gAddFolder hwndBtnAddFolder, 📂 Add Folder  
    Gui, Add, Button, x235 y200 w100 h32 gRemoveFiles hwndBtnRemoveFiles, ❌ Remove
    Gui, Add, Button, x345 y200 w80 h32 gClearFiles hwndBtnClearFiles, 🗑️ Clear
    
    ; Info tipi supportati
    Gui, Font, s8 c0x757575
    Gui, Add, Text, x450 y210 w300 vSupportedTypesText, Supported: Loading...
    
    ; Lista file con colonne dettagliate
    Gui, Add, ListView, x35 y240 w710 h140 vFileList gFileListEvents +Grid, File|Size|Type|Status
    
    ; === SEZIONE OUTPUT ===  
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y410 w760 h85 Section, 💾 Output Configuration
    
    Gui, Font, s9 Normal
    Gui, Add, Text, x35 y435, Output directory:
    Gui, Add, Edit, x35 y455 w600 vOutputFolder, %OUTPUT_FOLDER%
    Gui, Add, Button, x645 y454 w100 h23 gBrowseOutput hwndBtnBrowseOutput, 📁 Browse...
    
    ; === SEZIONE OPZIONI (Dinamica e Scalabile) ===
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y510 w760 h180 vOptionsGroupBox Section, ⚙️ Compression Options
    
    ; Le opzioni verranno create dinamicamente in RefreshGUI()
    
    ; === SEZIONE CONTROLLI ===
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y705 w760 h70 Section, 🚀 Job Control
    
    ; Pulsanti principali con icone
    Gui, Add, Button, x280 y730 w120 h35 gStartCompression hwndBtnStart, ▶️ Start Jobs
    Gui, Add, Button, x410 y730 w120 h35 gStopCompression hwndBtnStop Hidden, ⏹️ Stop All
    
    ; === APPLICAZIONE STILI ===
    ApplyButtonStyles()
    
    ; === MOSTRA FINESTRA ===
    Gui, Show, w800 h790, %APP_MAIN_NAME%
    
    ; Trigger refresh iniziale
    Gosub, FormatChanged
}

ApplyButtonStyles() {
    global
    
    ; Applica stili personalizzati ai bottoni
    ImageButton.Create(BtnAddFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnAddFolder, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnRemoveFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnClearFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnBrowseOutput, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnStart, GUI.buttons.success.normal, GUI.buttons.success.hover, GUI.buttons.success.clicked, GUI.buttons.success.disabled)
    ImageButton.Create(BtnStop, GUI.buttons.danger.normal, GUI.buttons.danger.hover, GUI.buttons.danger.clicked, GUI.buttons.danger.disabled)
}

; ========================================
; SISTEMA MENU AVANZATO
; ========================================

CreateAdvancedMenus() {
    global
    
    ; === FILE MENU ===
    Menu, FileMenu, Add, &New Session, MenuNewSession
    Menu, FileMenu, Add
    Menu, FileMenu, Add, &Load Session..., MenuLoadSession  
    Menu, FileMenu, Add, &Save Session..., MenuSaveSession
    Menu, FileMenu, Add
    Menu, FileMenu, Add, &Recent Sessions, :RecentMenu
    Menu, FileMenu, Add
    Menu, FileMenu, Add, E&xit, MenuExit
    
    ; === EDIT MENU ===
    Menu, EditMenu, Add, &Add Files..., AddFiles
    Menu, EditMenu, Add, Add &Folder..., AddFolder
    Menu, EditMenu, Add
    Menu, EditMenu, Add, &Remove Selected, RemoveFiles
    Menu, EditMenu, Add, &Clear All, ClearFiles
    Menu, EditMenu, Add
    Menu, EditMenu, Add, Select &All, MenuSelectAll
    
    ; === OPTIONS MENU ===
    Menu, OptionsMenu, Add, &Verbose Output, MenuToggleVerbose
    Menu, OptionsMenu, Add, &Delete Input Files, MenuToggleDeleteInput
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, &Settings..., MenuSettings
    Menu, OptionsMenu, Add, &Reset to Defaults, MenuResetDefaults
    
    ; === TOOLS MENU ===
    Menu, ToolsMenu, Add, &Batch Convert..., MenuBatchConvert
    Menu, ToolsMenu, Add, &Compare Formats..., MenuCompareFormats
    Menu, ToolsMenu, Add
    Menu, ToolsMenu, Add, View &Logs, MenuViewLogs
    Menu, ToolsMenu, Add, &Test CLI Tool, MenuTestCLI
    
    ; === HELP MENU ===
    Menu, HelpMenu, Add, &User Guide, MenuUserGuide
    Menu, HelpMenu, Add, &Supported Formats, MenuSupportedFormats
    Menu, HelpMenu, Add
    Menu, HelpMenu, Add, &GitHub Repository, MenuGitHub
    Menu, HelpMenu, Add, &Report Issue, MenuReportIssue
    Menu, HelpMenu, Add
    Menu, HelpMenu, Add, &About..., MenuAbout
    
    ; === MENU PRINCIPALE ===
    Menu, MainMenuBar, Add, &File, :FileMenu
    Menu, MainMenuBar, Add, &Edit, :EditMenu
    Menu, MainMenuBar, Add, &Options, :OptionsMenu
    Menu, MainMenuBar, Add, &Tools, :ToolsMenu
    Menu, MainMenuBar, Add, &Help, :HelpMenu
    
    Gui, Menu, MainMenuBar
    
    ; Configura check iniziali
    UpdateMenuChecks()
}

UpdateMenuChecks() {
    global
    
    ; Aggiorna checkmarks nei menu
    if (VERBOSE_MODE) {
        Menu, OptionsMenu, Check, &Verbose Output
    } else {
        Menu, OptionsMenu, Uncheck, &Verbose Output
    }
    
    if (DELETE_INPUT) {
        Menu, OptionsMenu, Check, &Delete Input Files
    } else {
        Menu, OptionsMenu, Uncheck, &Delete Input Files
    }
}

; ========================================
; GESTIONE EVENTI
; ========================================

FormatChanged:
    GuiControlGet, selectedText,, CompressionFormat
    
    ; Trova e imposta formato corrente
    for formatKey, formatData in COMPRESSION_FORMATS {
        if (InStr(selectedText, formatData.name) = 1) {
            CURRENT_FORMAT := formatKey
            break
        }
    }
    
    ; Refresh GUI con nuovo formato
    RefreshGUI()
return

ShowWelcomeMessage:
    ; Mostra messaggio di benvenuto in status bar
    SB_SetText("Welcome! Select a compression format and add files to begin.", 1)
    SetTimer, ClearWelcomeMessage, -5000
return

ClearWelcomeMessage:
    SB_SetText("Ready", 1)
return

; ========================================
; HANDLERS MENU
; ========================================

MenuNewSession:
    ; Reset sessione
    INPUT_FILES := []
    RefreshFileList()
    SB_SetText("New session started", 1)
return

MenuToggleVerbose:
    VERBOSE_MODE := !VERBOSE_MODE
    UpdateMenuChecks()
    SB_SetText("Verbose mode " . (VERBOSE_MODE ? "enabled" : "disabled"), 1)
return

MenuToggleDeleteInput:
    DELETE_INPUT := !DELETE_INPUT
    UpdateMenuChecks()
    SB_SetText("Delete input files " . (DELETE_INPUT ? "enabled" : "disabled"), 1)
return

MenuAbout:
    aboutText := APP_MAIN_NAME . "`n`n"
    aboutText .= "Universal ISO compression tool with scalable architecture`n"
    aboutText .= "supporting multiple formats and easy extensibility.`n`n"
    aboutText .= "Supported formats: " . GetSupportedFormatsString() . "`n`n"
    aboutText .= "Built with modern GUI design and efficient compression algorithms.`n`n"
    aboutText .= "© 2025 - Open Source Project"
    
    MsgBox, 64, About %APP_NAME%, %aboutText%
return

MenuGitHub:
    Run, https://github.com/Ashnar2602/Universal_Compression_Tool
return

MenuExit:
GuiClose:
    SaveSettings()
    ExitApp

; ========================================
; UTILITY FUNCTIONS
; ========================================

GetSupportedFormatsString() {
    global
    
    result := ""
    for formatKey, formatData in COMPRESSION_FORMATS {
        result .= (result ? ", " : "") . formatData.name
    }
    return result
}

LoadSettings() {
    global
    
    ; Carica impostazioni da file INI
    IniRead, OUTPUT_FOLDER, %SETTINGS_FILE%, General, OutputFolder, %A_ScriptDir%\compressed
    IniRead, CURRENT_FORMAT, %SETTINGS_FILE%, General, CurrentFormat, CSO
    IniRead, VERBOSE_MODE, %SETTINGS_FILE%, General, VerboseMode, 0
    IniRead, DELETE_INPUT, %SETTINGS_FILE%, General, DeleteInput, 0
    
    ; Converte stringhe in boolean
    VERBOSE_MODE := (VERBOSE_MODE = "1" || VERBOSE_MODE = "true")
    DELETE_INPUT := (DELETE_INPUT = "1" || DELETE_INPUT = "true")
}

SaveSettings() {
    global
    
    ; Salva impostazioni correnti
    GuiControlGet, outputFolder,, OutputFolder, Text
    if (outputFolder) {
        OUTPUT_FOLDER := outputFolder
    }
    
    IniWrite, %OUTPUT_FOLDER%, %SETTINGS_FILE%, General, OutputFolder
    IniWrite, %CURRENT_FORMAT%, %SETTINGS_FILE%, General, CurrentFormat
    IniWrite, % (VERBOSE_MODE ? "1" : "0"), %SETTINGS_FILE%, General, VerboseMode
    IniWrite, % (DELETE_INPUT ? "1" : "0"), %SETTINGS_FILE%, General, DeleteInput
}

; ========================================
; SISTEMA ROBUSTO DI REFRESH GUI
; ========================================

RefreshGUI() {
    global
    
    ; Ottieni formato corrente
    currentFormat := GetCurrentFormatData()
    if (!currentFormat) {
        return
    }
    
    ; Aggiorna descrizione formato
    GuiControl,, FormatDescription, %currentFormat.description%
    
    ; Aggiorna tipi supportati
    supportedText := "Supported types: " . JoinArray(currentFormat.inputExts, ", ", ".")
    GuiControl,, SupportedTypesText, %supportedText%
    
    ; Aggiorna status bar formato
    SB_SetText("Format: " . currentFormat.name, 3)
    
    ; Ricrea controlli opzioni
    RecreateOptionsControls(currentFormat)
    
    ; Filtra e aggiorna lista file
    RefreshFileList()
}

GetCurrentFormatData() {
    global
    
    return COMPRESSION_FORMATS[CURRENT_FORMAT]
}

RecreateOptionsControls(format) {
    global
    
    ; Per semplicità, nascondiamo tutti i controlli esistenti
    ; e creiamo quelli nuovi (AutoHotkey non supporta rimozione dinamica facile)
    ClearPreviousOptionsControls()
    
    ; Crea nuovi controlli
    CreateDynamicOptionsControls(format)
}

ClearPreviousOptionsControls() {
    ; Hide existing option controls
    ; In una implementazione completa, useremmo GUI destruction/recreation
}

CreateDynamicOptionsControls(format) {
    global
    
    yPos := 540
    xPos := 40
    maxWidth := 700
    colWidth := 340
    
    for optionKey, optionData in format.options {
        ; Crea label descrittivo
        Gui, Font, s9 Bold
        Gui, Add, Text, x%xPos% y%yPos% w%colWidth% h20 v%optionKey%_Label, % optionData.displayName
        
        ; Descrizione opzione
        Gui, Font, s8 c0x757575 
        Gui, Add, Text, x%xPos% y%yPos%+18 w%colWidth% h15 v%optionKey%_Desc, % optionData.description
        
        ; Controllo principale
        Gui, Font, s9 Normal c0x212121
        controlY := yPos + 38
        
        if (optionData.type = "checkbox") {
            checked := optionData.default ? "Checked" : ""
            Gui, Add, Checkbox, x%xPos% y%controlY% w%colWidth% v%optionKey%_Control %checked%, % optionData.displayName
        }
        else if (optionData.type = "dropdown") {
            valueList := ""
            if (optionData.descriptions) {
                ; Con descrizioni
                Loop, % optionData.values.Length() {
                    valueList .= optionData.descriptions[A_Index] . "|"
                }
            } else {
                ; Solo valori
                valueList := JoinArray(optionData.values, "|")
            }
            valueList := RTrim(valueList, "|")
            
            Gui, Add, DropDownList, x%xPos% y%controlY% w%colWidth% v%optionKey%_Control, %valueList%
            
            ; Seleziona default
            defaultIndex := GetArrayIndex(optionData.values, optionData.default)
            if (defaultIndex > 0) {
                GuiControl, Choose, %optionKey%_Control, %defaultIndex%
            }
        }
        else if (optionData.type = "slider") {
            range := "Range" . optionData.min . "-" . optionData.max
            Gui, Add, Slider, x%xPos% y%controlY% w%colWidth%-60 v%optionKey%_Control gUpdateSliderValue %range%, % optionData.default
            Gui, Add, Text, x%xPos%+%colWidth%-50 y%controlY%+3 w50 v%optionKey%_Value, % optionData.default
        }
        else if (optionData.type = "edit") {
            Gui, Add, Edit, x%xPos% y%controlY% w%colWidth% v%optionKey%_Control, % optionData.default
        }
        
        ; Avanza posizione (layout a due colonne)
        xPos += colWidth + 20
        if (xPos > maxWidth) {
            xPos := 40
            yPos += 80
        }
    }
}
