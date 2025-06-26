; ========================================
; UNIVERSAL ISO COMPRESSION TOOL - GUI ENHANCED
; Architettura scalabile per futuri formati/codec
; ========================================

#SingleInstance Force
#NoEnv
#Persistent
DetectHiddenWindows On
SetTitleMatchMode 3
SetWorkingDir %A_ScriptDir%

; Include dei moduli necessari
#Include ClassImageButton.ahk
#Include ConsoleClass.ahk
#Include JSON.ahk
#Include SelectFolderEx.ahk
#Include FormatRegistry.ahk
#Include JobProcessor.ahk

; ========================================
; CONFIGURAZIONE APPLICAZIONE
; ========================================

APP_NAME := "Universal ISO Compression Tool"
APP_VERSION := "2.0.0-Enhanced"
APP_MAIN_NAME := APP_NAME " v" APP_VERSION
CLI_EXECUTABLE := A_ScriptDir . "\bin\universal-compressor.exe"

; Verifica che il CLI esista
if (!FileExist(CLI_EXECUTABLE)) {
    MsgBox, 48, Missing CLI Tool, 
    (
    The CLI executable was not found: %CLI_EXECUTABLE%
    
    Please build the project first:
    1. Run setup_dev_env.bat to install build tools
    2. Run quick_build.bat to compile the CLI tool
    3. Then restart this GUI
    
    Current working directory: %A_ScriptDir%
    )
    ExitApp
}

; ========================================
; SISTEMA FORMATI SCALABILE
; ========================================

; Inizializza registry dei formati
COMPRESSION_FORMATS := {}
FORMAT_ORDER := []

; Funzione per registrare un nuovo formato di compressione
RegisterCompressionFormat(formatKey, formatConfig) {
    global COMPRESSION_FORMATS, FORMAT_ORDER
    
    ; Validazione configurazione formato
    if (!formatConfig.hasKey("name") || !formatConfig.hasKey("displayName") || !formatConfig.hasKey("cliParam")) {
        throw Exception("Invalid format configuration: missing required fields")
    }
    
    ; Registro formato
    COMPRESSION_FORMATS[formatKey] := formatConfig
    FORMAT_ORDER.Push(formatKey)
    
    ; Log registrazione
    OutputDebug, Registered compression format: %formatKey%
}

; Funzione per ottenere formati supportati
GetSupportedFormats() {
    global FORMAT_ORDER
    return FORMAT_ORDER
}

; Funzione per ottenere estensioni supportate per un formato
GetSupportedExtensions(formatKey) {
    global COMPRESSION_FORMATS
    
    if (COMPRESSION_FORMATS.hasKey(formatKey)) {
        return COMPRESSION_FORMATS[formatKey].inputExts
    }
    return []
}

; ========================================
; REGISTRAZIONE FORMATI PREDEFINITI
; ========================================

; CSO Format
RegisterCompressionFormat("CSO", {
    name: "CSO",
    displayName: "🎮 CSO - Compressed ISO for PSP/PS2",
    description: "Optimized for PSP and PS2 emulators like PPSSPP and PCSX2. Excellent balance between size and speed.",
    cliParam: "cso",
    inputExts: ["iso", "bin", "img"],
    outputExts: ["cso", "cso2", "zso", "dax"],
    defaultOutputExt: "cso",
    category: "Gaming",
    priority: 1,
    
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
            description: "Number of compression threads",
            type: "slider",
            min: 1, max: 16, default: 4,
            cliParam: "--cso-threads"
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
})

; CHD Format  
RegisterCompressionFormat("CHD", {
    name: "CHD",
    displayName: "🕹️ CHD - Compressed Hunks of Data",
    description: "MAME arcade and console disc format with excellent compression. Best for retro arcade and console emulation.",
    cliParam: "chd",
    inputExts: ["iso", "bin", "img", "cue"],
    outputExts: ["chd"],
    defaultOutputExt: "chd",
    category: "Arcade",
    priority: 2,
    
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
})

; ========================================
; SISTEMA PLUGIN FUTURI (PLACEHOLDER)
; ========================================

; Funzione per caricare plugin esterni
LoadCompressionPlugins() {
    global
    
    ; Scan per file plugin nella cartella plugins/
    pluginFolder := A_ScriptDir . "\plugins"
    
    if (FileExist(pluginFolder)) {
        Loop, Files, %pluginFolder%\*.ahk
        {
            ; Carica e registra plugin
            try {
                FileRead, pluginContent, %A_LoopFileFullPath%
                ; TODO: Implementare parser plugin sicuro
                OutputDebug, Found plugin: %A_LoopFileName%
            } catch e {
                OutputDebug, Failed to load plugin: %A_LoopFileName% - %e.message%
            }
        }
    }
}

; ========================================
; CONFIGURAZIONE GUI MIGLIORATA
; ========================================

GUI := {}
GUI.Theme := {
    Primary: 0xFF2196F3,
    PrimaryLight: 0xFF42A5F5,
    PrimaryDark: 0xFF1976D2,
    Secondary: 0xFF4CAF50,
    Background: 0xFFF5F5F5,
    Surface: 0xFFFFFFFF,
    TextPrimary: 0xFF212121,
    TextSecondary: 0xFF757575,
    Border: 0xFFE0E0E0,
    Error: 0xFFF44336,
    Warning: 0xFFFF9800,
    Success: 0xFF4CAF50
}

GUI.buttons := {}
GUI.buttons.default := {normal:[0, GUI.Theme.Surface, "", GUI.Theme.TextPrimary, 2], hover:[0, 0xFFE0E0E0, "", GUI.Theme.Primary, 2], clicked:[0, 0xFFD0D0D0, "", GUI.Theme.PrimaryDark, 2], disabled:[0, 0xFFF5F5F5, "", 0xFFBDBDBD, 2]}
GUI.buttons.primary := {normal:[0, GUI.Theme.Primary, "", "White", 3], hover:[0, GUI.Theme.PrimaryLight, "", "White", 3], clicked:[0, GUI.Theme.PrimaryDark, "", "White", 3], disabled:[0, 0xFFBBBBBB, "", "White", 3]}
GUI.buttons.success := {normal:[0, GUI.Theme.Success, "", "White", 3], hover:[0, 0xFF45A049, "", "White", 3], clicked:[0, 0xFF3E8B41, "", "White", 3], disabled:[0, 0xFFBBBBBB, "", "White", 3]}
GUI.buttons.danger := {normal:[0, GUI.Theme.Error, "", "White", 3], hover:[0, 0xFFE53935, "", "White", 3], clicked:[0, 0xFFD32F2F, "", "White", 3], disabled:[0, 0xFFBBBBBB, "", "White", 3]}

; ========================================
; VARIABILI GLOBALI
; ========================================

CURRENT_FORMAT := ""
INPUT_FILES := []
OUTPUT_FOLDER := A_ScriptDir . "\compressed"
SETTINGS_FILE := "UniversalCompressorEnhanced.ini"
VERBOSE_MODE := false
DELETE_INPUT := false

; Job processing
CURRENT_JOB_INDEX := 0
TOTAL_JOBS := 0
JOBS_COMPLETED := 0
JOBS_FAILED := 0
IS_PROCESSING := false

; Opzioni dinamiche
CURRENT_OPTIONS := {}
OPTION_CONTROLS := {}

; ========================================
; INIZIALIZZAZIONE
; ========================================

LoadCompressionPlugins()
LoadSettings()
CreateMainGUI()
CreateMenus()
RefreshGUI()

; Mostra messaggio di benvenuto
SetTimer, ShowWelcome, -1000

return

; ========================================
; CREAZIONE GUI PRINCIPALE MIGLIORATA
; ========================================

CreateMainGUI() {
    global
    
    ; Configurazione finestra con ridimensionamento
    Gui, +Resize +MinSize900x700 +MaxSize1400x1000
    Gui, Color, % GUI.Theme.Background
    
    ; Status bar migliorata
    Gui, Add, StatusBar, , Ready
    SB_SetParts(150, 150, 150, 200, -1)
    SB_SetText("Ready", 1)
    SB_SetText("Files: 0", 2)
    SB_SetText("Format: None", 3)
    SB_SetText("Queue: 0", 4)
    SB_SetText(APP_MAIN_NAME, 5)
    
    ; Header migliorato
    Gui, Font, s18 Bold, Segoe UI
    GuiControl, Font, HeaderTitle
    Gui, Add, Text, x20 y15 w860 Center vHeaderTitle c0x2196F3, %APP_NAME%
    
    Gui, Font, s10 Normal c0x757575, Segoe UI
    Gui, Add, Text, x20 y45 w860 Center, Universal compression tool with scalable architecture for multiple formats
    
    ; Sezione selezione formato migliorata
    Gui, Font, s10 Bold c0x212121, Segoe UI
    Gui, Add, GroupBox, x20 y75 w860 h120 vFormatSelectionGroup, 🎯 Compression Format Selection
    
    Gui, Font, s9 Normal, Segoe UI
    Gui, Add, Text, x35 y100, Choose compression format:
    
    ; Dropdown formati dinamico
    formatList := BuildFormatDropdown()
    Gui, Add, DropDownList, x35 y120 w600 vCompressionFormat gFormatChanged, %formatList%
    
    ; Info formato
    Gui, Font, s8 c0x757575, Segoe UI
    Gui, Add, Text, x35 y150 w800 h35 vFormatDescription +Wrap, Select a compression format to see description and options...
    
    ; Sezione input files migliorata
    Gui, Font, s10 Bold c0x212121, Segoe UI
    Gui, Add, GroupBox, x20 y205 w860 h240 vInputFilesGroup, 📁 Input Files Management
    
    ; Toolbar file migliorata
    Gui, Font, s9 Normal, Segoe UI
    Gui, Add, Button, x35 y230 w100 h35 gAddFiles hwndBtnAddFiles, 📄 Add Files
    Gui, Add, Button, x145 y230 w100 h35 gAddFolder hwndBtnAddFolder, 📂 Add Folder
    Gui, Add, Button, x255 y230 w100 h35 gRemoveFiles hwndBtnRemoveFiles, ❌ Remove
    Gui, Add, Button, x365 y230 w80 h35 gClearFiles hwndBtnClearFiles, 🗑️ Clear
    
    ; Drag & Drop area
    Gui, Add, Text, x470 y235 w380 h25 Center c0x757575 BackgroundTrans vDropZone, Or drag and drop files here →
    
    ; Info tipi supportati
    Gui, Font, s8 c0x757575, Segoe UI
    Gui, Add, Text, x35 y275 w800 vSupportedTypesText, Supported file types: Select a format first...
    
    ; Lista file migliorata
    Gui, Add, ListView, x35 y295 w820 h140 vFileList gFileListEvents +Grid +LV0x10000, File|Size|Format|Status|Progress
    
    ; Sezione output migliorata
    Gui, Font, s10 Bold c0x212121, Segoe UI
    Gui, Add, GroupBox, x20 y455 w860 h85 vOutputGroup, 💾 Output Configuration
    
    Gui, Font, s9 Normal, Segoe UI
    Gui, Add, Text, x35 y480, Output directory:
    Gui, Add, Edit, x35 y500 w700 vOutputFolder, %OUTPUT_FOLDER%
    Gui, Add, Button, x745 y499 w120 h23 gBrowseOutput hwndBtnBrowseOutput, 📁 Browse...
    
    ; Sezione opzioni dinamica
    Gui, Font, s10 Bold c0x212121, Segoe UI
    Gui, Add, GroupBox, x20 y550 w860 h200 vOptionsGroup, ⚙️ Compression Options
    
    ; Area scroll per opzioni future
    Gui, Add, Text, x35 y575 w820 h160 vOptionsArea Center c0x757575, Select a compression format to configure options...
    
    ; Sezione controlli migliorata
    Gui, Font, s10 Bold c0x212121, Segoe UI
    Gui, Add, GroupBox, x20 y760 w860 h80 vControlsGroup, 🚀 Job Control
    
    ; Pulsanti principali con spacing migliorato
    Gui, Add, Button, x300 y785 w140 h40 gStartCompression hwndBtnStart Disabled, ▶️ Start Jobs
    Gui, Add, Button, x450 y785 w140 h40 gStopCompression hwndBtnStop Hidden, ⏹️ Stop All
    
    ; Progress bar generale (nascosta inizialmente)
    Gui, Add, Progress, x35 y810 w820 h15 vOverallProgress Hidden, 0
    
    ; Applica stili
    ApplyButtonStyles()
    
    ; Mostra finestra
    Gui, Show, w900 h860, %APP_MAIN_NAME%
    
    ; Setup drag & drop
    SetupDragDrop()
    
    ; Trigger refresh iniziale
    SetTimer, InitialFormatSelection, -100
}

; Costruisce dinamicamente la lista dropdown dei formati
BuildFormatDropdown() {
    global FORMAT_ORDER, COMPRESSION_FORMATS
    
    formatList := ""
    for index, formatKey in FORMAT_ORDER {
        formatData := COMPRESSION_FORMATS[formatKey]
        formatList .= formatData.displayName . "|"
    }
    
    return RTrim(formatList, "|")
}

; ========================================
; GESTIONE EVENTI GUI
; ========================================

FormatChanged:
    Gui, Submit, NoHide
    
    ; Determina il formato selezionato
    selectedIndex := CompressionFormat
    if (selectedIndex > 0 && selectedIndex <= FORMAT_ORDER.Length()) {
        CURRENT_FORMAT := FORMAT_ORDER[selectedIndex]
        UpdateFormatInfo()
        CreateDynamicOptions()
        RefreshGUI()
    }
return

UpdateFormatInfo() {
    global CURRENT_FORMAT, COMPRESSION_FORMATS
    
    if (CURRENT_FORMAT != "" && COMPRESSION_FORMATS.hasKey(CURRENT_FORMAT)) {
        formatData := COMPRESSION_FORMATS[CURRENT_FORMAT]
        
        ; Aggiorna descrizione
        GuiControl,, FormatDescription, %formatData.description%
        
        ; Aggiorna tipi supportati
        extList := ""
        for index, ext in formatData.inputExts {
            extList .= "*." . ext . " "
        }
        GuiControl,, SupportedTypesText, Supported file types: %extList%
        
        ; Aggiorna status bar
        SB_SetText("Format: " . formatData.name, 3)
    }
}

CreateDynamicOptions() {
    global CURRENT_FORMAT, COMPRESSION_FORMATS, OPTION_CONTROLS, CURRENT_OPTIONS
    
    ; Clear existing options
    for controlName, controlData in OPTION_CONTROLS {
        GuiControl, Destroy, %controlName%
    }
    OPTION_CONTROLS := {}
    CURRENT_OPTIONS := {}
    
    if (CURRENT_FORMAT == "" || !COMPRESSION_FORMATS.hasKey(CURRENT_FORMAT)) {
        GuiControl,, OptionsArea, Select a compression format to configure options...
        return
    }
    
    formatData := COMPRESSION_FORMATS[CURRENT_FORMAT]
    if (!formatData.hasKey("options")) {
        GuiControl,, OptionsArea, No additional options available for this format.
        return
    }
    
    ; Hide the placeholder text
    GuiControl, Hide, OptionsArea
    
    ; Create dynamic controls for each option
    yPos := 580
    for optionKey, optionData in formatData.options {
        CreateOptionControl(optionKey, optionData, yPos)
        yPos += 35
        
        ; Store default value
        CURRENT_OPTIONS[optionKey] := optionData.default
    }
}

CreateOptionControl(optionKey, optionData, yPos) {
    global OPTION_CONTROLS
    
    ; Label
    Gui, Font, s9 Normal, Segoe UI
    labelName := "Label_" . optionKey
    Gui, Add, Text, x45 y%yPos% w200 v%labelName%, % optionData.displayName . ":"
    OPTION_CONTROLS[labelName] := {type: "label", optionKey: optionKey}
    
    ; Control based on type
    controlName := "Control_" . optionKey
    controlX := 250
    
    if (optionData.type == "dropdown") {
        valueList := ""
        for index, value in optionData.values {
            valueList .= value . "|"
        }
        valueList := RTrim(valueList, "|")
        
        ; Find default index
        defaultIndex := 1
        for index, value in optionData.values {
            if (value == optionData.default) {
                defaultIndex := index
                break
            }
        }
        
        Gui, Add, DropDownList, x%controlX% y%yPos% w200 v%controlName% Choose%defaultIndex%, %valueList%
        
    } else if (optionData.type == "slider") {
        Gui, Add, Slider, x%controlX% y%yPos% w200 h20 v%controlName% Range%optionData.min%-%optionData.max% TickInterval5, % optionData.default
        ; Add value display
        valueName := "Value_" . optionKey
        Gui, Add, Text, x460 y%yPos% w50 v%valueName%, % optionData.default
        OPTION_CONTROLS[valueName] := {type: "value", optionKey: optionKey}
        
    } else if (optionData.type == "checkbox") {
        checkedState := optionData.default ? "Checked" : ""
        Gui, Add, Checkbox, x%controlX% y%yPos% v%controlName% %checkedState%, % optionData.description
        
    } else if (optionData.type == "edit") {
        Gui, Add, Edit, x%controlX% y%yPos% w200 v%controlName%, % optionData.default
    }
    
    OPTION_CONTROLS[controlName] := {type: optionData.type, optionKey: optionKey, data: optionData}
}

; ========================================
; GESTIONE FILE E JOB INTEGRATA
; ========================================

AddFiles:
    ; Build dynamic file dialog
    filterString := BuildFileDialog()
    
    FileSelectFile, selectedFiles, M3, , Select files to compress, %filterString%
    
    if (selectedFiles != "") {
        AddFilesToList(selectedFiles)
        RefreshGUI()
    }
return

AddFolder:
    ; Select folder for recursive scanning
    SelectFolderEx.SelectFolderEx("Select folder containing files to compress", "", FolderCallback)
return

FolderCallback:
    selectedFolder := SelectFolderEx.GetResult()
    if (selectedFolder != "") {
        ScanFolderForFiles(selectedFolder)
    }
return

ScanFolderForFiles(folderPath) {
    global CURRENT_FORMAT, COMPRESSION_FORMATS
    
    if (CURRENT_FORMAT == "") {
        MsgBox, 48, No Format Selected, Please select a compression format first.
        return
    }
    
    formatData := COMPRESSION_FORMATS[CURRENT_FORMAT]
    
    ; Build search pattern for supported extensions
    searchPatterns := []
    for index, ext in formatData.inputExts {
        searchPatterns.Push(folderPath . "\*." . ext)
    }
    
    ; Scan each pattern
    filesFound := 0
    for index, pattern in searchPatterns {
        Loop, Files, %pattern%, R  ; R for recursive
        {
            AddSingleFile(A_LoopFileFullPath)
            filesFound++
        }
    }
    
    UpdateFileList()
    
    if (filesFound > 0) {
        SB_SetText("Found " . filesFound . " files in folder", 1)
    } else {
        MsgBox, 64, No Files Found, No supported files found in the selected folder.
    }
}

AddFilesToList(fileList) {
    global INPUT_FILES, CURRENT_FORMAT, COMPRESSION_FORMATS
    
    if (CURRENT_FORMAT == "") {
        MsgBox, 48, No Format Selected, Please select a compression format first.
        return
    }
    
    ; Parse file list
    StringSplit, files, fileList, `n
    
    if (files0 > 1) {
        ; Multiple files - first entry is directory
        baseDir := files1
        Loop, % files0 - 1 {
            filePath := baseDir . "\" . files%A_Index+1%
            AddSingleFile(filePath)
        }
    } else {
        ; Single file
        AddSingleFile(fileList)
    }
    
    UpdateFileList()
}

AddSingleFile(filePath) {
    global INPUT_FILES, CURRENT_FORMAT, COMPRESSION_FORMATS
    
    if (!FileExist(filePath)) {
        return
    }
    
    ; Check if already added
    for index, existingFile in INPUT_FILES {
        if (existingFile.path == filePath) {
            return ; Already exists
        }
    }
    
    ; Validate extension
    SplitPath, filePath, fileName, fileDir, fileExt
    
    formatData := COMPRESSION_FORMATS[CURRENT_FORMAT]
    validExt := false
    for index, ext in formatData.inputExts {
        if (fileExt == ext) {
            validExt := true
            break
        }
    }
    
    if (!validExt) {
        MsgBox, 48, Invalid File Type, File type ".%fileExt%" is not supported by %formatData.name% format.
        return
    }
    
    ; Add to list
    FileGetSize, fileSize, %filePath%
    INPUT_FILES.Push({
        path: filePath,
        name: fileName,
        size: fileSize,
        sizeText: FormatBytes(fileSize),
        status: "Pending",
        progress: 0
    })
}

UpdateFileList() {
    global INPUT_FILES
    
    ; Clear ListView
    Gui, ListView, FileList
    LV_Delete()
    
    ; Add files
    for index, file in INPUT_FILES {
        LV_Add("", file.name, file.sizeText, CURRENT_FORMAT, file.status, file.progress . "%")
    }
    
    ; Update UI
    SB_SetText("Files: " . INPUT_FILES.Length(), 2)
    SB_SetText("Queue: " . INPUT_FILES.Length(), 4)
    
    ; Enable/disable start button
    GuiControl, % (INPUT_FILES.Length() > 0 ? "Enable" : "Disable"), BtnStart
}

RemoveFiles:
    Gui, ListView, FileList
    
    ; Get selected rows
    selectedRows := []
    RowNumber := 0
    Loop {
        RowNumber := LV_GetNext(RowNumber)
        if (!RowNumber)
            break
        selectedRows.Push(RowNumber)
    }
    
    ; Remove from array (reverse order to maintain indices)
    Loop, % selectedRows.Length() {
        index := selectedRows.Length() - A_Index + 1
        INPUT_FILES.RemoveAt(selectedRows[index])
    }
    
    UpdateFileList()
return

ClearFiles:
    INPUT_FILES := []
    UpdateFileList()
return

; ========================================
; UTILITÀ E HELPER
; ========================================

FormatBytes(bytes) {
    if (bytes >= 1073741824) {
        return Round(bytes / 1073741824, 2) . " GB"
    } else if (bytes >= 1048576) {
        return Round(bytes / 1048576, 2) . " MB"
    } else if (bytes >= 1024) {
        return Round(bytes / 1024, 2) . " KB"
    } else {
        return bytes . " bytes"
    }
}

RefreshGUI() {
    ; Aggiorna elementi GUI basati sullo stato attuale
    ; Implementazione futura per refresh automatico
}

; ========================================
; ========================================
; PLACEHOLDER FUNCTIONS IMPLEMENTATION
; ========================================

InitialFormatSelection:
    ; Seleziona automaticamente il primo formato
    if (FORMAT_ORDER.Length() > 0) {
        GuiControl, Choose, CompressionFormat, 1
        Gosub, FormatChanged
    }
return

ShowWelcome:
    SB_SetText("Welcome! Select files and choose compression format to begin.", 1)
return

BrowseOutput:
    FileSelectFolder, selectedFolder, , 3, Select output folder for compressed files
    if (selectedFolder != "") {
        GuiControl,, OutputFolder, %selectedFolder%
        OUTPUT_FOLDER := selectedFolder
    }
return

FileListEvents:
    if (A_GuiEvent == "DoubleClick") {
        ; Show file details on double-click
        Gui, ListView, FileList
        selectedRow := LV_GetNext()
        if (selectedRow > 0) {
            ShowFileDetails(selectedRow)
        }
    }
return

ShowFileDetails(rowNumber) {
    Gui, ListView, FileList
    
    LV_GetText, fileName, %rowNumber%, 1
    LV_GetText, fileSize, %rowNumber%, 2
    LV_GetText, format, %rowNumber%, 3
    LV_GetText, status, %rowNumber%, 4
    LV_GetText, progress, %rowNumber%, 5
    
    ; Find full path
    fullPath := ""
    for index, file in INPUT_FILES {
        if (file.name == fileName) {
            fullPath := file.path
            break
        }
    }
    
    details := "File Details:`n`n"
    details .= "Name: " . fileName . "`n"
    details .= "Path: " . fullPath . "`n"
    details .= "Size: " . fileSize . "`n"
    details .= "Format: " . format . "`n"
    details .= "Status: " . status . "`n"
    details .= "Progress: " . progress
    
    MsgBox, 64, File Details, %details%
}

SetupDragDrop:
    ; Enable drag & drop functionality (placeholder)
    ; Would require additional DLL calls for full implementation
return

ApplyButtonStyles() {
    global
    
    ; Apply modern button styles using ImageButton
    try {
        ImageButton.Create(BtnAddFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
        ImageButton.Create(BtnAddFolder, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
        ImageButton.Create(BtnRemoveFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
        ImageButton.Create(BtnClearFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
        ImageButton.Create(BtnBrowseOutput, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
        ImageButton.Create(BtnStart, GUI.buttons.success.normal, GUI.buttons.success.hover, GUI.buttons.success.clicked, GUI.buttons.success.disabled)
        ImageButton.Create(BtnStop, GUI.buttons.danger.normal, GUI.buttons.danger.hover, GUI.buttons.danger.clicked, GUI.buttons.danger.disabled)
    } catch e {
        ; Fallback if ImageButton fails
        OutputDebug, Button styling failed: %e.message%
    }
}

CreateMenus() {
    global
    
    ; File menu
    Menu, FileMenu, Add, &New Session, MenuNewSession
    Menu, FileMenu, Add
    Menu, FileMenu, Add, &Load Session..., MenuLoadSession
    Menu, FileMenu, Add, &Save Session..., MenuSaveSession
    Menu, FileMenu, Add
    Menu, FileMenu, Add, E&xit, MenuExit
    
    ; Edit menu
    Menu, EditMenu, Add, &Add Files..., AddFiles
    Menu, EditMenu, Add, Add &Folder..., AddFolder
    Menu, EditMenu, Add
    Menu, EditMenu, Add, &Remove Selected, RemoveFiles
    Menu, EditMenu, Add, &Clear All, ClearFiles
    Menu, EditMenu, Add
    Menu, EditMenu, Add, Select &All, MenuSelectAll
    
    ; Tools menu
    Menu, ToolsMenu, Add, &Queue Manager..., MenuQueueManager
    Menu, ToolsMenu, Add, &Statistics..., MenuStatistics
    Menu, ToolsMenu, Add
    Menu, ToolsMenu, Add, &Presets..., MenuPresets
    
    ; Options menu
    Menu, OptionsMenu, Add, &Verbose Output, MenuToggleVerbose
    Menu, OptionsMenu, Add, &Delete Input Files, MenuToggleDeleteInput
    Menu, OptionsMenu, Add, &Play Completion Sound, MenuToggleSound
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, &Concurrent Jobs..., MenuConcurrentJobs
    Menu, OptionsMenu, Add, &Settings..., MenuSettings
    
    ; Help menu
    Menu, HelpMenu, Add, &About..., MenuAbout
    Menu, HelpMenu, Add, &User Guide, MenuUserGuide
    Menu, HelpMenu, Add, &GitHub Repository, MenuGitHub
    Menu, HelpMenu, Add
    Menu, HelpMenu, Add, &Check for Updates, MenuCheckUpdates
    
    ; Main menu bar
    Menu, MainMenuBar, Add, &File, :FileMenu
    Menu, MainMenuBar, Add, &Edit, :EditMenu
    Menu, MainMenuBar, Add, &Tools, :ToolsMenu
    Menu, MainMenuBar, Add, &Options, :OptionsMenu
    Menu, MainMenuBar, Add, &Help, :HelpMenu
    
    Gui, Menu, MainMenuBar
    
    UpdateMenuChecks()
}

UpdateMenuChecks() {
    global
    
    ; Update menu checkmarks based on current settings
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

LoadSettings() {
    global
    
    ; Load settings from INI file
    IniRead, OUTPUT_FOLDER, %SETTINGS_FILE%, General, OutputFolder, %A_ScriptDir%\compressed
    IniRead, CURRENT_FORMAT, %SETTINGS_FILE%, General, CurrentFormat, CSO
    IniRead, VERBOSE_MODE, %SETTINGS_FILE%, General, VerboseMode, 0
    IniRead, DELETE_INPUT, %SETTINGS_FILE%, General, DeleteInput, 0
    
    ; Ensure output folder exists
    if (!FileExist(OUTPUT_FOLDER)) {
        FileCreateDir, %OUTPUT_FOLDER%
    }
    
    ; Convert string to boolean
    VERBOSE_MODE := (VERBOSE_MODE == "1" || VERBOSE_MODE == "true")
    DELETE_INPUT := (DELETE_INPUT == "1" || DELETE_INPUT == "true")
}
StartCompression:
    if (INPUT_FILES.Length() == 0) {
        MsgBox, 48, No Files, Please add files to compress first.
        return
    }
    
    if (CURRENT_FORMAT == "") {
        MsgBox, 48, No Format, Please select a compression format first.
        return
    }
    
    ; Get current options
    CollectCurrentOptions()
    
    ; Validate output folder
    Gui, Submit, NoHide
    if (OutputFolder == "" || !FileExist(OutputFolder)) {
        MsgBox, 48, Invalid Output, Please select a valid output folder.
        return
    }
    
    ; Start batch compression
    jobIDs := StartBatchCompression(INPUT_FILES, OutputFolder, CURRENT_FORMAT, CURRENT_OPTIONS)
    
    if (jobIDs.Length() > 0) {
        SB_SetText("Started " . jobIDs.Length() . " compression jobs", 1)
    }
return

StopCompression:
    queueManager := JobQueueManager.GetInstance()
    queueManager.StopProcessing()
return

CollectCurrentOptions() {
    global CURRENT_OPTIONS, OPTION_CONTROLS
    
    ; Collect values from dynamic option controls
    for controlName, controlData in OPTION_CONTROLS {
        if (controlData.type != "label" && controlData.type != "value") {
            GuiControlGet, value, , %controlName%
            
            optionKey := controlData.optionKey
            if (controlData.type == "checkbox") {
                CURRENT_OPTIONS[optionKey] := (value == 1)
            } else {
                CURRENT_OPTIONS[optionKey] := value
            }
        }
    }
}
FileListEvents:
SetupDragDrop:
CreateMenus:
LoadSettings:
    ; Placeholder implementations
return

; ========================================
; EVENT HANDLERS
; ========================================

GuiClose:
GuiEscape:
ExitApp

; ========================================
; CONFIGURAZIONE SALVATAGGIO/CARICAMENTO
; ========================================

SaveSettings() {
    ; Implementazione futura
}

; ========================================
; MENU HANDLERS
; ========================================

MenuNewSession:
    ; Clear all files and reset
    ClearFiles()
    GuiControl, Choose, CompressionFormat, 1
    Gosub, FormatChanged
    SB_SetText("New session started", 1)
return

MenuLoadSession:
    ; Load session from file (future implementation)
    MsgBox, 64, Feature Coming Soon, Session loading will be implemented in a future version.
return

MenuSaveSession:
    ; Save current session to file (future implementation)
    MsgBox, 64, Feature Coming Soon, Session saving will be implemented in a future version.
return

MenuExit:
    ; Stop any running jobs before exit
    queueManager := JobQueueManager.GetInstance()
    queueManager.StopProcessing()
    ExitApp
return

MenuSelectAll:
    Gui, ListView, FileList
    Loop % LV_GetCount() {
        LV_Modify(A_Index, Select)
    }
return

MenuQueueManager:
    ; Show queue management window (future implementation)
    ShowQueueManagerWindow()
return

MenuStatistics:
    ; Show compression statistics window
    ShowStatisticsWindow()
return

MenuPresets:
    ; Show presets management window (future implementation)
    MsgBox, 64, Feature Coming Soon, Preset management will be implemented in a future version.
return

MenuToggleVerbose:
    VERBOSE_MODE := !VERBOSE_MODE
    UpdateMenuChecks()
    SaveSettings()
return

MenuToggleDeleteInput:
    DELETE_INPUT := !DELETE_INPUT
    UpdateMenuChecks()
    SaveSettings()
return

MenuToggleSound:
    ; Toggle completion sound (future setting)
    MsgBox, 64, Feature Coming Soon, Sound settings will be implemented in a future version.
return

MenuConcurrentJobs:
    ; Show concurrent jobs setting dialog
    ShowConcurrentJobsDialog()
return

MenuSettings:
    ; Show main settings window
    ShowSettingsWindow()
return

MenuAbout:
    ShowAboutDialog()
return

MenuUserGuide:
    ; Open user guide (could open README.md)
    if (FileExist("README.md")) {
        Run, notepad.exe README.md
    } else {
        MsgBox, 64, User Guide, Please refer to the README.md file in the project directory for detailed usage instructions.
    }
return

MenuGitHub:
    Run, https://github.com/Ashnar2602/Universal_Compression_Tool
return

MenuCheckUpdates:
    ; Check for updates (future implementation)
    MsgBox, 64, Feature Coming Soon, Update checking will be implemented in a future version.
return

; ========================================
; DIALOG WINDOWS
; ========================================

ShowQueueManagerWindow() {
    global
    
    queueStatus := JobQueueManager.GetInstance().GetQueueStatus()
    
    info := "Queue Manager`n`n"
    info .= "Jobs in queue: " . queueStatus.queueLength . "`n"
    info .= "Active jobs: " . queueStatus.activeJobs . "`n"
    info .= "Processing: " . (queueStatus.isProcessing ? "Yes" : "No") . "`n"
    info .= "Paused: " . (queueStatus.isPaused ? "Yes" : "No") . "`n`n"
    info .= "Total jobs: " . JOB_STATS.totalJobs . "`n"
    info .= "Completed: " . JOB_STATS.completedJobs . "`n"
    info .= "Failed: " . JOB_STATS.failedJobs
    
    MsgBox, 64, Queue Manager, %info%
}

ShowStatisticsWindow() {
    global JOB_STATS
    
    stats := "Compression Statistics`n`n"
    stats .= "Total jobs processed: " . (JOB_STATS.completedJobs + JOB_STATS.failedJobs) . "`n"
    stats .= "Successful: " . JOB_STATS.completedJobs . "`n"
    stats .= "Failed: " . JOB_STATS.failedJobs . "`n`n"
    
    if (JOB_STATS.totalInputSize > 0) {
        stats .= "Total input size: " . FormatBytes(JOB_STATS.totalInputSize) . "`n"
        stats .= "Total output size: " . FormatBytes(JOB_STATS.totalOutputSize) . "`n"
        
        if (JOB_STATS.totalOutputSize > 0) {
            totalRatio := Round((1 - JOB_STATS.totalOutputSize / JOB_STATS.totalInputSize) * 100, 2)
            spaceSaved := JOB_STATS.totalInputSize - JOB_STATS.totalOutputSize
            stats .= "Space saved: " . FormatBytes(spaceSaved) . " (" . totalRatio . "%)`n"
        }
    }
    
    if (JOB_STATS.totalTimeSpent > 0) {
        stats .= "Total time spent: " . FormatTime(JOB_STATS.totalTimeSpent)
    }
    
    MsgBox, 64, Statistics, %stats%
}

ShowConcurrentJobsDialog() {
    queueManager := JobQueueManager.GetInstance()
    currentMax := queueManager.maxConcurrentJobs
    
    InputBox, newMax, Concurrent Jobs, Enter maximum number of concurrent compression jobs:, , 300, 130, , , , , %currentMax%
    
    if (!ErrorLevel && newMax != "" && newMax > 0 && newMax <= 16) {
        queueManager.SetMaxConcurrentJobs(newMax)
        SB_SetText("Max concurrent jobs set to " . newMax, 1)
    } else if (!ErrorLevel) {
        MsgBox, 48, Invalid Input, Please enter a number between 1 and 16.
    }
}

ShowSettingsWindow() {
    ; Create settings window (simplified version)
    Gui, Settings:New, +ToolWindow, Settings
    Gui, Settings:Add, Text, x10 y10, Output folder:
    Gui, Settings:Add, Edit, x10 y30 w300 vSettingsOutputFolder, %OUTPUT_FOLDER%
    Gui, Settings:Add, Button, x320 y29 w50 h23 gSettingsBrowseFolder, Browse
    
    Gui, Settings:Add, Checkbox, x10 y60 vSettingsVerbose % (VERBOSE_MODE ? "Checked" : ""), Verbose output
    Gui, Settings:Add, Checkbox, x10 y80 vSettingsDeleteInput % (DELETE_INPUT ? "Checked" : ""), Delete input files after compression
    
    Gui, Settings:Add, Button, x250 y110 w60 h30 gSettingsSave, Save
    Gui, Settings:Add, Button, x320 y110 w60 h30 gSettingsCancel, Cancel
    
    Gui, Settings:Show, w390 h150
return

SettingsBrowseFolder:
    Gui, Settings:Submit, NoHide
    FileSelectFolder, newFolder, %SettingsOutputFolder%, 3, Select output folder
    if (newFolder != "") {
        GuiControl, Settings:, SettingsOutputFolder, %newFolder%
    }
return

SettingsSave:
    Gui, Settings:Submit
    
    ; Apply settings
    OUTPUT_FOLDER := SettingsOutputFolder
    VERBOSE_MODE := SettingsVerbose
    DELETE_INPUT := SettingsDeleteInput
    
    ; Update main GUI
    GuiControl,, OutputFolder, %OUTPUT_FOLDER%
    UpdateMenuChecks()
    
    ; Save to file
    SaveSettings()
    
    SB_SetText("Settings saved", 1)
return

SettingsCancel:
    Gui, Settings:Destroy
return

ShowAboutDialog() {
    aboutText := APP_MAIN_NAME . "`n`n"
    aboutText .= "Universal ISO compression tool with scalable architecture`n"
    aboutText .= "Supports multiple compression formats and future expansion`n`n"
    aboutText .= "Supported formats:`n"
    
    global COMPRESSION_FORMATS
    for formatKey, formatData in COMPRESSION_FORMATS {
        aboutText .= "• " . formatData.name . " - " . formatData.description . "`n"
    }
    
    aboutText .= "`nDeveloped with AutoHotkey and C++`n"
    aboutText .= "© 2025 Universal Compression Tool Team"
    
    MsgBox, 64, About, %aboutText%
}

; ========================================
; CONFIGURAZIONE SALVATAGGIO/CARICAMENTO COMPLETA
; ========================================

SaveSettings() {
    global
    
    ; Save current settings to INI file
    IniWrite, %OUTPUT_FOLDER%, %SETTINGS_FILE%, General, OutputFolder
    IniWrite, %CURRENT_FORMAT%, %SETTINGS_FILE%, General, CurrentFormat
    IniWrite, % (VERBOSE_MODE ? "1" : "0"), %SETTINGS_FILE%, General, VerboseMode
    IniWrite, % (DELETE_INPUT ? "1" : "0"), %SETTINGS_FILE%, General, DeleteInput
    
    ; Save current options for each format
    for formatKey, formatData in COMPRESSION_FORMATS {
        if (formatData.hasKey("options")) {
            for optionKey, optionData in formatData.options {
                if (CURRENT_OPTIONS.hasKey(optionKey)) {
                    IniWrite, % CURRENT_OPTIONS[optionKey], %SETTINGS_FILE%, %formatKey%, %optionKey%
                }
            }
        }
    }
}
