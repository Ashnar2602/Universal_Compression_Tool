; ========================================
; UNIVERSAL ISO COMPRESSION TOOL - GUI
; Versione unificata e completa
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

; ========================================
; CONFIGURAZIONE APPLICAZIONE
; ========================================

APP_NAME := "Universal ISO Compression Tool"
APP_VERSION := "2.0.0-GUI"
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
; ARCHITETTURA SCALABILE FORMATI
; ========================================

COMPRESSION_FORMATS := {}

; Formato CSO
COMPRESSION_FORMATS.CSO := {
    name: "CSO",
    displayName: "🎮 CSO - Compressed ISO for PSP/PS2",
    description: "Optimized for PSP and PS2 emulators like PPSSPP and PCSX2",
    cliParam: "cso",
    inputExts: ["iso", "bin", "img"],
    outputExts: ["cso", "cso2", "zso", "dax"],
    defaultOutputExt: "cso",
    
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
}

; Formato CHD
COMPRESSION_FORMATS.CHD := {
    name: "CHD",
    displayName: "🕹️ CHD - Compressed Hunks of Data",
    description: "MAME arcade and console disc format with excellent compression",
    cliParam: "chd",
    inputExts: ["iso", "bin", "img", "cue"],
    outputExts: ["chd"],
    defaultOutputExt: "chd",
    
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
; CONFIGURAZIONE GUI
; ========================================

GUI := {}
GUI.buttons := {}
GUI.buttons.default := {normal:[0, 0xFFEEEEEE, "", 0xFF212121, 2], hover:[0, 0xFFE0E0E0, "", 0xFF1976D2, 2], clicked:[0, 0xFFD0D0D0, "", 0xFF0D47A1, 2], disabled:[0, 0xFFF5F5F5, "", 0xFFBDBDBD, 2]}
GUI.buttons.primary := {normal:[0, 0xFF2196F3, "", "White", 3], hover:[0, 0xFF1976D2, "", "White", 3], clicked:[0, 0xFF0D47A1, "", "White", 3], disabled:[0, 0xFFBBBBBB, "", "White", 3]}
GUI.buttons.success := {normal:[0, 0xFF4CAF50, "", "White", 3], hover:[0, 0xFF45A049, "", "White", 3], clicked:[0, 0xFF3E8B41, "", "White", 3], disabled:[0, 0xFFBBBBBB, "", "White", 3]}
GUI.buttons.danger := {normal:[0, 0xFFF44336, "", "White", 3], hover:[0, 0xFFE53935, "", "White", 3], clicked:[0, 0xFFD32F2F, "", "White", 3], disabled:[0, 0xFFBBBBBB, "", "White", 3]}

; Variabili globali
CURRENT_FORMAT := "CSO"
INPUT_FILES := []
OUTPUT_FOLDER := A_ScriptDir "\compressed"
SETTINGS_FILE := "UniversalCompressor.ini"
VERBOSE_MODE := false
DELETE_INPUT := false

; Variabili job processing
CURRENT_JOB_INDEX := 0
TOTAL_JOBS := 0
JOBS_COMPLETED := 0
JOBS_FAILED := 0
IS_PROCESSING := false

; ========================================
; INIZIALIZZAZIONE
; ========================================

LoadSettings()
CreateMainGUI()
CreateMenus()
RefreshGUI()

; Messaggio di benvenuto
SetTimer, ShowWelcome, -1000

return

; ========================================
; FUNZIONI GUI - ARCHITETTURA SCALABILE
; ========================================

; ========================================
; CREAZIONE GUI PRINCIPALE
; ========================================

CreateMainGUI() {
    global
    
    ; Configurazione finestra
    Gui, +Resize +MinSize800x600
    Gui, Color, 0xF5F5F5
    
    ; Status bar
    Gui, Add, StatusBar, , Ready
    SB_SetParts(200, 200, 200, -1)
    SB_SetText("Ready", 1)
    SB_SetText("Files: 0", 2)
    SB_SetText("Format: " . CURRENT_FORMAT, 3)
    SB_SetText(APP_MAIN_NAME, 4)
    
    ; Header
    Gui, Font, s16 Bold c0x2196F3
    Gui, Add, Text, x20 y15 w760 Center, %APP_NAME%
    Gui, Font, s9 Normal c0x757575
    Gui, Add, Text, x20 y45 w760 Center, Universal compression tool with scalable architecture
    
    ; Sezione selezione formato
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y70 w760 h90, 🎯 Compression Format Selection
    
    Gui, Font, s9 Normal
    Gui, Add, Text, x35 y95, Choose compression format:
    
    ; Dropdown formati
    formatList := ""
    for formatKey, formatData in COMPRESSION_FORMATS {
        formatList .= formatData.displayName . "|"
    }
    formatList := RTrim(formatList, "|")
    
    Gui, Add, DropDownList, x35 y115 w500 vCompressionFormat gFormatChanged Choose1, %formatList%
    
    ; Descrizione formato
    Gui, Font, s8 c0x757575
    Gui, Add, Text, x35 y145 w600 h20 vFormatDescription, Loading format description...
    
    ; Sezione input files
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y175 w760 h220, 📁 Input Files Management
    
    ; Toolbar file
    Gui, Font, s9 Normal
    Gui, Add, Button, x35 y200 w90 h32 gAddFiles hwndBtnAddFiles, 📄 Add Files
    Gui, Add, Button, x135 y200 w90 h32 gAddFolder hwndBtnAddFolder, 📂 Add Folder
    Gui, Add, Button, x235 y200 w100 h32 gRemoveFiles hwndBtnRemoveFiles, ❌ Remove
    Gui, Add, Button, x345 y200 w80 h32 gClearFiles hwndBtnClearFiles, 🗑️ Clear
    
    ; Info tipi supportati
    Gui, Font, s8 c0x757575
    Gui, Add, Text, x450 y210 w300 vSupportedTypesText, Supported: Loading...
    
    ; Lista file
    Gui, Add, ListView, x35 y240 w710 h140 vFileList gFileListEvents +Grid, File|Size|Type|Status
    
    ; Sezione output
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y410 w760 h85, 💾 Output Configuration
    
    Gui, Font, s9 Normal
    Gui, Add, Text, x35 y435, Output directory:
    Gui, Add, Edit, x35 y455 w600 vOutputFolder, %OUTPUT_FOLDER%
    Gui, Add, Button, x645 y454 w100 h23 gBrowseOutput hwndBtnBrowseOutput, 📁 Browse...
    
    ; Sezione opzioni (dinamica)
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y510 w760 h180 vOptionsGroupBox, ⚙️ Compression Options
    
    ; Sezione controlli
    Gui, Font, s9 Bold c0x212121
    Gui, Add, GroupBox, x20 y705 w760 h70, 🚀 Job Control
    
    ; Pulsanti principali
    Gui, Add, Button, x280 y730 w120 h35 gStartCompression hwndBtnStart, ▶️ Start Jobs
    Gui, Add, Button, x410 y730 w120 h35 gStopCompression hwndBtnStop Hidden, ⏹️ Stop All
    
    ; Applica stili
    ApplyButtonStyles()
    
    ; Mostra finestra
    Gui, Show, w800 h790, %APP_MAIN_NAME%
    
    ; Trigger refresh iniziale
    Gosub, FormatChanged
}

ApplyButtonStyles() {
    global
    
    ImageButton.Create(BtnAddFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnAddFolder, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnRemoveFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnClearFiles, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnBrowseOutput, GUI.buttons.default.normal, GUI.buttons.default.hover, GUI.buttons.default.clicked, GUI.buttons.default.disabled)
    ImageButton.Create(BtnStart, GUI.buttons.success.normal, GUI.buttons.success.hover, GUI.buttons.success.clicked, GUI.buttons.success.disabled)
    ImageButton.Create(BtnStop, GUI.buttons.danger.normal, GUI.buttons.danger.hover, GUI.buttons.danger.clicked, GUI.buttons.danger.disabled)
}

; ========================================
; MENU SYSTEM
; ========================================

CreateMenus() {
    global
    
    ; File menu
    Menu, FileMenu, Add, &New Session, MenuNewSession
    Menu, FileMenu, Add
    Menu, FileMenu, Add, E&xit, MenuExit
    
    ; Edit menu
    Menu, EditMenu, Add, &Add Files..., AddFiles
    Menu, EditMenu, Add, Add &Folder..., AddFolder
    Menu, EditMenu, Add
    Menu, EditMenu, Add, &Remove Selected, RemoveFiles
    Menu, EditMenu, Add, &Clear All, ClearFiles
    
    ; Options menu
    Menu, OptionsMenu, Add, &Verbose Output, MenuToggleVerbose
    Menu, OptionsMenu, Add, &Delete Input Files, MenuToggleDeleteInput
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, &Settings..., MenuSettings
    
    ; Help menu
    Menu, HelpMenu, Add, &About..., MenuAbout
    Menu, HelpMenu, Add, &GitHub Repository, MenuGitHub
    
    ; Main menu bar
    Menu, MainMenuBar, Add, &File, :FileMenu
    Menu, MainMenuBar, Add, &Edit, :EditMenu
    Menu, MainMenuBar, Add, &Options, :OptionsMenu
    Menu, MainMenuBar, Add, &Help, :HelpMenu
    
    Gui, Menu, MainMenuBar
    
    UpdateMenuChecks()
}

UpdateMenuChecks() {
    global
    
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
; FUNZIONE SCALABILE PER REFRESH GUI
; ========================================

RefreshGUI() {
    global
    
    ; Ottieni formato corrente
    currentFormat := GetCurrentFormat()
    
    if (!currentFormat) {
        return
    }
    
    ; Aggiorna testo tipi supportati
    supportedText := "Supported: " . JoinArray(currentFormat.inputExts, ", ")
    GuiControl,, SupportedTypesText, %supportedText%
    
    ; Rimuovi controlli opzioni esistenti
    ClearOptionsControls()
    
    ; Crea controlli opzioni dinamicamente
    CreateOptionsControls(currentFormat)
    
    ; Aggiorna lista file (filtra per estensioni supportate)
    RefreshFileList()
}

; ========================================
; GESTIONE DINAMICA DELLE OPZIONI
; ========================================

CreateOptionsControls(format) {
    global
    
    yPos := 540
    xPos := 40
    
    for optionKey, optionData in format.options {
        ; Label
        Gui, Font, s9 Bold
        Gui, Add, Text, x%xPos% y%yPos% w200 v%optionKey%_Label, % optionData.displayName ":":
        
        ; Description
        Gui, Font, s8 c0x757575
        Gui, Add, Text, x%xPos% y%yPos%+18 w200 v%optionKey%_Desc, % optionData.description
        
        ; Control
        Gui, Font, s9 Normal c0x212121
        controlY := yPos + 38
        
        if (optionData.type = "checkbox") {
            checked := optionData.default ? "Checked" : ""
            Gui, Add, Checkbox, x%xPos% y%controlY% w200 v%optionKey%_Control %checked%, % optionData.displayName
        }
        else if (optionData.type = "dropdown") {
            if (optionData.descriptions) {
                valueList := JoinArray(optionData.descriptions, "|")
            } else {
                valueList := JoinArray(optionData.values, "|")
            }
            
            Gui, Add, DropDownList, x%xPos% y%controlY% w200 v%optionKey%_Control, %valueList%
            
            ; Select default
            defaultIndex := GetArrayIndex(optionData.values, optionData.default)
            if (defaultIndex > 0) {
                GuiControl, Choose, %optionKey%_Control, %defaultIndex%
            }
        }
        else if (optionData.type = "slider") {
            range := "Range" . optionData.min . "-" . optionData.max
            Gui, Add, Slider, x%xPos% y%controlY% w180 v%optionKey%_Control %range%, % optionData.default
            Gui, Add, Text, x%xPos%+190 y%controlY%+3 w30 v%optionKey%_Value, % optionData.default
        }
        else if (optionData.type = "edit") {
            Gui, Add, Edit, x%xPos% y%controlY% w200 v%optionKey%_Control, % optionData.default
        }
        
        ; Avanza posizione
        xPos += 380
        if (xPos > 700) {
            xPos := 40
            yPos += 80
        }
    }
}

ClearOptionsControls() {
    ; Implementation for clearing existing controls
    ; For simplicity, we'll hide them (AutoHotkey limitation)
}

; ========================================
; UTILITY FUNCTIONS SCALABILI
; ========================================

GetCurrentFormat() {
    global
    
    GuiControlGet, selectedText,, CompressionFormat
    
    ; Trova formato basato sul nome
    for formatKey, formatData in COMPRESSION_FORMATS {
        if (InStr(selectedText, formatData.name) = 1) {
            return formatData
        }
    }
    
    return false
}

BuildCommandLine() {
    global
    
    currentFormat := GetCurrentFormat()
    if (!currentFormat) {
        return ""
    }
    
    ; Comando base
    cmd := CLI_EXECUTABLE . " --type=" . currentFormat.cliParam
    
    ; Aggiungi opzioni specifiche
    for optionKey, optionData in currentFormat.options {
        value := GetOptionValue(optionKey, optionData)
        
        if (value != "" && optionData.cliParam) {
            if (optionData.type = "checkbox") {
                if (optionData.inverted) {
                    ; Per parametri "no-" invertiti (es. --cso-no-zlib)
                    if (!value) {
                        cmd .= " " . optionData.cliParam
                    }
                } else {
                    ; Parametri normali
                    if (value) {
                        cmd .= " " . optionData.cliParam
                    }
                }
            } else {
                cmd .= " " . optionData.cliParam . "=" . value
            }
        }
    }
    
    return cmd
}

GetOptionValue(optionKey, optionData) {
    controlName := optionKey . "_Control"
    
    if (optionData.type = "checkbox") {
        GuiControlGet, checked,, %controlName%
        return checked
    }
    else if (optionData.type = "dropdown") {
        GuiControlGet, selectedIndex,, %controlName%
        if (selectedIndex > 0 && selectedIndex <= optionData.values.Length()) {
            return optionData.values[selectedIndex]
        }
    }
    else {
        GuiControlGet, value,, %controlName%
        return value
    }
    
    return ""
}

ValidateForCompression() {
    global
    
    if (INPUT_FILES.Length() = 0) {
        MsgBox, 48, Error, Please add files to compress.
        return false
    }
    
    GuiControlGet, outputFolder,, OutputFolder
    if (!outputFolder) {
        MsgBox, 48, Error, Please select an output folder.
        return false
    }
    
    if (!FileExist(outputFolder)) {
        FileCreateDir, %outputFolder%
        if (ErrorLevel) {
            MsgBox, 48, Error, Cannot create output folder: %outputFolder%
            return false
        }
    }
    
    return true
}

SetGUIState(state) {
    global
    
    if (state = "compressing") {
        GuiControl, Disable, CompressionFormat
        GuiControl, Disable, BtnAddFiles
        GuiControl, Disable, BtnAddFolder
        GuiControl, Disable, BtnRemoveFiles
        GuiControl, Disable, BtnClearFiles
        GuiControl, Disable, BtnStart
        GuiControl, Show, BtnStop
    } else {
        GuiControl, Enable, CompressionFormat
        GuiControl, Enable, BtnAddFiles
        GuiControl, Enable, BtnAddFolder
        GuiControl, Enable, BtnRemoveFiles
        GuiControl, Enable, BtnClearFiles
        GuiControl, Enable, BtnStart
        GuiControl, Hide, BtnStop
    }
}

AddFilesToList(selectedFiles) {
    global
    
    StringSplit, fileArray, selectedFiles, `n
    baseDir := fileArray1
    
    if (fileArray0 = 1) {
        AddSingleFileToList(selectedFiles)
        return
    }
    
    Loop, %fileArray0% {
        if (A_Index = 1) {
            continue
        }
        
        fullPath := baseDir . "\" . fileArray%A_Index%
        AddSingleFileToList(fullPath)
    }
}

AddSingleFileToList(filePath) {
    global
    
    ; Check if already exists
    for index, existingFile in INPUT_FILES {
        if (existingFile.path = filePath) {
            return
        }
    }
    
    ; Get file info
    FileGetSize, fileSize, %filePath%
    fileSizeMB := Round(fileSize / 1024 / 1024, 2)
    
    SplitPath, filePath, fileName, fileDir, fileExt
    
    ; Check extension
    currentFormat := GetCurrentFormat()
    if (!IsExtensionSupported(fileExt, currentFormat.inputExts)) {
        MsgBox, 48, Warning, File type .%fileExt% is not supported for %currentFormat.name% compression.
        return
    }
    
    ; Add to list
    fileInfo := {path: filePath, name: fileName, size: fileSize, sizeMB: fileSizeMB, status: "Ready", ext: fileExt}
    INPUT_FILES.Push(fileInfo)
}

AddFolderToList(folderPath) {
    global
    
    currentFormat := GetCurrentFormat()
    
    for index, ext in currentFormat.inputExts {
        searchPattern := folderPath . "\*." . ext
        
        Loop, Files, %searchPattern%
        {
            AddSingleFileToList(A_LoopFileFullPath)
        }
    }
}

RefreshFileList() {
    global
    
    Gui, ListView, FileList
    LV_Delete()
    
    for index, fileInfo in INPUT_FILES {
        LV_Add("", fileInfo.name, fileInfo.sizeMB . " MB", fileInfo.ext, fileInfo.status)
    }
    
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
    LV_ModifyCol(4, "AutoHdr")
    
    fileCount := INPUT_FILES.Length()
    SB_SetText("Files: " . fileCount, 2)
}

UpdateFileStatus(fileIndex, status) {
    global
    
    INPUT_FILES[fileIndex].status := status
    
    Gui, ListView, FileList
    LV_Modify(fileIndex, Col4, status)
}

IsExtensionSupported(ext, supportedExts) {
    for index, supportedExt in supportedExts {
        if (ext = supportedExt) {
            return true
        }
    }
    return false
}

JoinArray(array, separator, prefix := "") {
    result := ""
    for index, value in array {
        result .= (index > 1 ? separator : "") . prefix . value
    }
    return result
}

GetArrayIndex(array, value) {
    for index, item in array {
        if (item = value) {
            return index
        }
    }
    return 0
}

LoadSettings() {
    global
    IniRead, OUTPUT_FOLDER, %SETTINGS_FILE%, General, OutputFolder, %A_ScriptDir%\compressed
    IniRead, CURRENT_FORMAT, %SETTINGS_FILE%, General, CurrentFormat, CSO
    IniRead, VERBOSE_MODE, %SETTINGS_FILE%, General, VerboseMode, 0
    IniRead, DELETE_INPUT, %SETTINGS_FILE%, General, DeleteInput, 0
    
    VERBOSE_MODE := (VERBOSE_MODE = "1")
    DELETE_INPUT := (DELETE_INPUT = "1")
}

SaveSettings() {
    global
    
    GuiControlGet, outputFolder,, OutputFolder
    if (outputFolder) {
        OUTPUT_FOLDER := outputFolder
    }
    
    IniWrite, %OUTPUT_FOLDER%, %SETTINGS_FILE%, General, OutputFolder
    IniWrite, %CURRENT_FORMAT%, %SETTINGS_FILE%, General, CurrentFormat
    IniWrite, % (VERBOSE_MODE ? "1" : "0"), %SETTINGS_FILE%, General, VerboseMode
    IniWrite, % (DELETE_INPUT ? "1" : "0"), %SETTINGS_FILE%, General, DeleteInput
}

; ========================================
; EVENT HANDLERS
; ========================================

FileListEvents:
    if (A_GuiEvent = "DoubleClick") {
        selectedRow := LV_GetNext()
        if (selectedRow > 0) {
            filePath := INPUT_FILES[selectedRow].path
            Run, explorer.exe /select`,"%filePath%"
        }
    }
return

; ========================================
; MENU HANDLERS
; ========================================

MenuNewSession:
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

MenuSettings:
    MsgBox, 64, Settings, Settings dialog coming soon!
return

MenuAbout:
    aboutText := APP_MAIN_NAME . "`n`n"
    aboutText .= "Universal ISO compression tool with scalable architecture.`n`n"
    aboutText .= "Supported formats: "
    for formatKey, formatData in COMPRESSION_FORMATS {
        aboutText .= formatData.name . " "
    }
    aboutText .= "`n`n© 2025 - Open Source Project"
    
    MsgBox, 64, About, %aboutText%
return

MenuGitHub:
    Run, https://github.com/Ashnar2602/Universal_Compression_Tool
return

MenuExit:
GuiClose:
    SaveSettings()
    ExitApp
