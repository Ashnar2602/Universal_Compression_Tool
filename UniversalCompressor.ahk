#SingleInstance Force
#NoEnv
#Persistent
DetectHiddenWindows On
SetTitleMatchMode 3
SetWorkingDir %A_ScriptDir%

; Include necessary libraries
#Include ClassImageButton.ahk
#Include ConsoleClass.ahk
#Include JSON.ahk
#Include SelectFolderEx.ahk

; Application constants
APP_NAME := "Universal ISO Compression Tool"
APP_VERSION := "1.0.0"
APP_AUTHOR := "Universal Compressor"

; File locations
MAXCSO_FILE_LOC := A_ScriptDir "\maxcso.exe"
CHDMAN_FILE_LOC := A_ScriptDir "\chdman.exe"

; Global variables
GUI := {}
JOB := {}
SETTINGS := {}

; Default settings
OUTPUT_FOLDER := A_Desktop
JOB_QUEUE_SIZE := 3
COMPRESSION_TYPE := "CSO"  ; Default compression type
SHOW_CONSOLE := "no"
REMOVE_FILES_AFTER_SUCCESS := "no"
PLAY_COMPLETION_SOUND := false

; Initialize application
Init()

; Main initialization function
Init() {
    ; Check if required executables exist
    CheckExecutables()
    
    ; Initialize GUI structure
    InitializeGUI()
    
    ; Create main GUI
    CreateMainGUI()
    
    ; Load settings
    LoadSettings()
    
    ; Show main window
    Gui, Main:Show, w600 h500, %APP_NAME% v%APP_VERSION%
    
    return
}

; Check if required executables exist
CheckExecutables() {
    missingFiles := ""
    
    if (!FileExist(MAXCSO_FILE_LOC)) {
        missingFiles .= "• maxcso.exe (for CSO compression)`n"
    }
    
    if (!FileExist(CHDMAN_FILE_LOC)) {
        missingFiles .= "• chdman.exe (for CHD compression)`n"
    }
    
    if (missingFiles != "") {
        MsgBox, 16, Missing Executables, The following required files are missing:`n`n%missingFiles%`nPlease place these files in the same directory as this application.
        ExitApp
    }
}

; Initialize GUI structure
InitializeGUI() {
    GUI := {
        compressionTypes: {
            CSO: {name: "CSO", desc: "PlayStation Portable compressed format", exe: "maxcso.exe"},
            CHD: {name: "CHD", desc: "MAME compressed hard disk format", exe: "chdman.exe"}
        },
        csoOptions: {
            threads: {name: "Threads", default: 4, desc: "Number of CPU threads to use"},
            format: {name: "Format", default: "cso1", options: "cso1|cso2|zso|dax", desc: "Output format"},
            blockSize: {name: "Block Size", default: "", desc: "Block size (leave empty for auto)"},
            useZlib: {name: "Use Zlib", default: true, desc: "Enable zlib compression"},
            use7zip: {name: "Use 7-Zip", default: true, desc: "Enable 7-zip deflate compression"},
            fast: {name: "Fast Mode", default: false, desc: "Use fast compression (lower quality)"}
        },
        chdOptions: {
            compression: {name: "Compression", default: "cdlz,cdzl,cdfl", desc: "Compression codecs"},
            hunkSize: {name: "Hunk Size", default: "19584", desc: "Size of each hunk in bytes"},
            numProcessors: {name: "Processors", default: 4, desc: "Number of processors to use"},
            force: {name: "Force Overwrite", default: true, desc: "Force overwriting existing files"}
        }
    }
    
    JOB := {
        queue: [],
        running: [],
        completed: [],
        failed: []
    }
}

; Create main GUI
CreateMainGUI() {
    Gui, Main:New, +Resize -MaximizeBox, %APP_NAME%
    Gui, Main:Font, s12 Bold
    Gui, Main:Add, Text, x20 y20 w560 Center, Universal ISO Compression Tool
    
    Gui, Main:Font, s9 Normal
    Gui, Main:Add, Text, x20 y50 w560 Center, Compress ISO files to CHD or CSO format
    
    ; Compression type selection
    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, x20 y80, Compression Type:
    Gui, Main:Font, s9 Normal
    Gui, Main:Add, Radio, x30 y100 w100 vRadioCSO Checked gCompressionTypeChanged, CSO Format
    Gui, Main:Add, Radio, x150 y100 w100 vRadioCHD gCompressionTypeChanged, CHD Format
    
    ; Description
    Gui, Main:Add, Text, x30 y120 w540 h40 vCompressionDesc, CSO (Compressed ISO): PlayStation Portable compressed format for PSP and PS2 emulators. Provides good compression ratios with fast decompression.
    
    ; Input files section
    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, x20 y170, Input Files:
    Gui, Main:Font, s9 Normal
    Gui, Main:Add, Button, x30 y190 w120 h30 gSelectFiles, Select ISO Files
    Gui, Main:Add, Button, x160 y190 w80 h30 gClearFiles, Clear All
    Gui, Main:Add, ListView, x30 y230 w540 h120 vFileList Grid, File|Size|Status
    
    ; Output folder section
    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, x20 y360, Output Folder:
    Gui, Main:Font, s9 Normal
    Gui, Main:Add, Edit, x30 y380 w450 h20 vOutputFolder ReadOnly, %OUTPUT_FOLDER%
    Gui, Main:Add, Button, x490 y378 w80 h24 gSelectOutputFolder, Browse
    
    ; Options section
    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, x20 y410, Options:
    Gui, Main:Font, s9 Normal
    CreateOptionsSection()
    
    ; Control buttons
    Gui, Main:Add, Button, x290 y460 w80 h30 gShowAdvancedOptions, Advanced
    Gui, Main:Add, Button, x380 y460 w80 h30 gStartCompression vStartBtn, Start
    Gui, Main:Add, Button, x470 y460 w80 h30 gStopCompression vStopBtn Disabled, Stop
    
    ; Status bar
    Gui, Main:Add, Text, x20 y500 w560 h20 vStatusBar, Ready
    
    return
}

; Create options section based on compression type
CreateOptionsSection() {
    ; This will be populated dynamically based on compression type
    Gui, Main:Add, CheckBox, x30 y430 w200 vOptionForce Checked, Force overwrite existing files
    Gui, Main:Add, CheckBox, x250 y430 w200 vOptionDeleteInput, Delete input files after success
}

; Event: Compression type changed
CompressionTypeChanged:
    Gui, Main:Submit, NoHide
    
    if (RadioCSO) {
        COMPRESSION_TYPE := "CSO"
        GuiControl, Main:, CompressionDesc, CSO (Compressed ISO): PlayStation Portable compressed format for PSP and PS2 emulators. Provides good compression ratios with fast decompression.
    } else {
        COMPRESSION_TYPE := "CHD"
        GuiControl, Main:, CompressionDesc, CHD (Compressed Hunks of Data): MAME compressed format for hard disk images. Excellent compression for arcade and computer system ROMs.
    }
    
    UpdateStatusBar("Compression type changed to " . COMPRESSION_TYPE)
return

; Event: Select input files
SelectFiles:
    FileSelectMultiple, SelectedFiles, 3,, Select ISO files to compress, ISO Files (*.iso;*.bin;*.img)
    
    if (ErrorLevel) {
        return
    }
    
    StringSplit, FileArray, SelectedFiles, `n
    basePath := FileArray1
    
    Loop, % FileArray0 - 1 {
        currentFile := basePath . "\" . FileArray%A_Index+1%
        
        ; Check if file already exists in list
        exists := false
        Loop % LV_GetCount() {
            LV_GetText, existingFile, %A_Index%, 1
            if (existingFile = currentFile) {
                exists := true
                break
            }
        }
        
        if (!exists) {
            FileGetSize, fileSize, %currentFile%
            fileSizeMB := Round(fileSize / 1048576, 2) . " MB"
            LV_Add("", currentFile, fileSizeMB, "Waiting")
        }
    }
    
    LV_ModifyCol()
    UpdateStatusBar(LV_GetCount() . " files selected for compression")
return

; Event: Clear file list
ClearFiles:
    LV_Delete()
    UpdateStatusBar("File list cleared")
return

; Event: Select output folder
SelectOutputFolder:
    FileSelectFolder, selectedFolder, *%OUTPUT_FOLDER%, 3, Select output folder
    if (selectedFolder != "") {
        OUTPUT_FOLDER := selectedFolder
        GuiControl, Main:, OutputFolder, %OUTPUT_FOLDER%
        UpdateStatusBar("Output folder set to: " . OUTPUT_FOLDER)
    }
return

; Event: Start compression
StartCompression:
    Gui, Main:Submit, NoHide
    
    ; Validate inputs
    if (LV_GetCount() = 0) {
        MsgBox, 16, Error, Please select at least one ISO file to compress.
        return
    }
    
    if (!FileExist(OUTPUT_FOLDER)) {
        MsgBox, 16, Error, Output folder does not exist. Please select a valid folder.
        return
    }
    
    ; Disable start button, enable stop button
    GuiControl, Main:Disable, StartBtn
    GuiControl, Main:Enable, StopBtn
    
    ; Start compression process
    StartCompressionProcess()
return

; Event: Stop compression
StopCompression:
    ; Implementation for stopping compression
    GuiControl, Main:Enable, StartBtn
    GuiControl, Main:Disable, StopBtn
    UpdateStatusBar("Compression stopped by user")
return

; Start the compression process
StartCompressionProcess() {
    totalFiles := LV_GetCount()
    completedFiles := 0
    failedFiles := 0
    
    Loop % totalFiles {
        LV_GetText, inputFile, %A_Index%, 1
        LV_Modify(A_Index, Col3, "Processing...")
        
        ; Generate output filename
        SplitPath, inputFile, fileName, fileDir, fileExt, fileNameNoExt
        
        startTime := A_TickCount
        
        if (COMPRESSION_TYPE = "CSO") {
            outputFile := OUTPUT_FOLDER . "\" . fileNameNoExt . ".cso"
            success := CompressToCSO(inputFile, outputFile, A_Index)
        } else {
            outputFile := OUTPUT_FOLDER . "\" . fileNameNoExt . ".chd"
            success := CompressToCHD(inputFile, outputFile, A_Index)
        }
        
        if (success) {
            completedFiles++
            elapsedTime := Round((A_TickCount - startTime) / 1000, 1)
            LV_Modify(A_Index, Col3, "Completed (" . elapsedTime . "s)")
        } else {
            failedFiles++
            LV_Modify(A_Index, Col3, "Failed")
        }
        
        ; Update progress
        progress := Round((A_Index / totalFiles) * 100)
        UpdateStatusBar("Progress: " . A_Index . "/" . totalFiles . " (" . progress . "%) - " . completedFiles . " completed, " . failedFiles . " failed")
    }
    
    ; Final summary
    UpdateStatusBar("Compression complete: " . completedFiles . " successful, " . failedFiles . " failed out of " . totalFiles . " total files")
    
    ; Re-enable controls when done
    GuiControl, Main:Enable, StartBtn
    GuiControl, Main:Disable, StopBtn
    
    ; Play completion sound if enabled
    if (PLAY_COMPLETION_SOUND) {
        SoundPlay, %A_WinDir%\Media\Windows Ding.wav
    }
}

; Compress file to CSO format
CompressToCSO(inputFile, outputFile, rowIndex) {
    ; Build maxcso command
    command := """" . MAXCSO_FILE_LOC . """"
    command .= " """ . inputFile . """"
    command .= " -o """ . outputFile . """"
    
    ; Add options based on GUI settings
    Gui, Main:Submit, NoHide
    
    ; Add threads option
    command .= " --threads=" . GetCSOThreads()
    
    ; Add format option
    format := GetCSOFormat()
    if (format != "cso1") {
        command .= " --format=" . format
    }
    
    ; Add compression options
    if (GetCSOUseZlib()) {
        command .= " --use-z-lib"
    }
    
    if (GetCSOUse7zip()) {
        command .= " --use-7zdeflate"
    }
    
    if (GetCSOFastMode()) {
        command .= " --fast"
    }
    
    ; Add block size if specified
    blockSize := GetCSOBlockSize()
    if (blockSize != "") {
        command .= " --block=" . blockSize
    }
    
    ; Log command if verbose mode is enabled
    if (SHOW_CONSOLE = "yes") {
        UpdateStatusBar("Executing: " . command)
    }
    
    ; Execute command
    RunWait, %command%,, Hide, processID
    
    ; Check if output file was created and update status
    if (FileExist(outputFile)) {
        ; Get file sizes for compression ratio
        FileGetSize, inputSize, %inputFile%
        FileGetSize, outputSize, %outputFile%
        ratio := Round(((inputSize - outputSize) / inputSize) * 100, 1)
        
        UpdateStatusBar("Successfully compressed: " . inputFile . " (Saved " . ratio . "%)")
        
        ; Delete input file if option is checked
        if (OptionDeleteInput) {
            FileDelete, %inputFile%
        }
        
        return true
    } else {
        UpdateStatusBar("Failed to compress: " . inputFile)
        return false
    }
}

; Compress file to CHD format
CompressToCHD(inputFile, outputFile, rowIndex) {
    ; Build chdman command
    command := """" . CHDMAN_FILE_LOC . """"
    command .= " createcd"
    command .= " -i """ . inputFile . """"
    command .= " -o """ . outputFile . """"
    
    ; Add options based on GUI settings
    Gui, Main:Submit, NoHide
    
    if (OptionForce) {
        command .= " -f"
    }
    
    ; Add compression codecs
    compression := GetCHDCompression()
    if (compression != "") {
        command .= " -c """ . compression . """"
    }
    
    ; Add hunk size
    hunkSize := GetCHDHunkSize()
    if (hunkSize != "" && hunkSize != "19584") {
        command .= " -hs " . hunkSize
    }
    
    ; Add number of processors
    processors := GetCHDProcessors()
    if (processors != "" && processors != "1") {
        command .= " -np " . processors
    }
    
    ; Log command if verbose mode is enabled
    if (SHOW_CONSOLE = "yes") {
        UpdateStatusBar("Executing: " . command)
    }
    
    ; Execute command
    RunWait, %command%,, Hide, processID
    
    ; Check if output file was created and update status
    if (FileExist(outputFile)) {
        ; Get file sizes for compression ratio
        FileGetSize, inputSize, %inputFile%
        FileGetSize, outputSize, %outputFile%
        ratio := Round(((inputSize - outputSize) / inputSize) * 100, 1)
        
        UpdateStatusBar("Successfully compressed: " . inputFile . " (Saved " . ratio . "%)")
        
        ; Delete input file if option is checked
        if (OptionDeleteInput) {
            FileDelete, %inputFile%
        }
        
        return true
    } else {
        UpdateStatusBar("Failed to compress: " . inputFile)
        return false
    }
}

; Update status bar
UpdateStatusBar(message) {
    GuiControl, Main:, StatusBar, %message%
}

; Load application settings
LoadSettings() {
    ; Implementation for loading settings from INI file
    IniRead, OUTPUT_FOLDER, Settings.ini, General, OutputFolder, %A_Desktop%
    IniRead, COMPRESSION_TYPE, Settings.ini, General, CompressionType, CSO
    
    GuiControl, Main:, OutputFolder, %OUTPUT_FOLDER%
    
    if (COMPRESSION_TYPE = "CHD") {
        GuiControl, Main:, RadioCHD, 1
        GuiControl, Main:, RadioCSO, 0
    }
}

; Save application settings
SaveSettings() {
    IniWrite, %OUTPUT_FOLDER%, Settings.ini, General, OutputFolder
    IniWrite, %COMPRESSION_TYPE%, Settings.ini, General, CompressionType
}

; Helper functions for getting configuration options
GetCSOThreads() {
    ; Get number of threads for CSO compression
    IniRead, threads, Settings.ini, CSO, Threads, 4
    return threads
}

GetCSOFormat() {
    ; Get CSO format
    IniRead, format, Settings.ini, CSO, Format, cso1
    return format
}

GetCSOUseZlib() {
    ; Get zlib usage setting
    IniRead, useZlib, Settings.ini, CSO, UseZlib, yes
    return (useZLib = "yes")
}

GetCSOUse7zip() {
    ; Get 7zip usage setting
    IniRead, use7zip, Settings.ini, CSO, Use7zip, yes
    return (use7zip = "yes")
}

GetCSOFastMode() {
    ; Get fast mode setting
    IniRead, fastMode, Settings.ini, CSO, FastMode, no
    return (fastMode = "yes")
}

GetCSOBlockSize() {
    ; Get block size setting
    IniRead, blockSize, Settings.ini, CSO, BlockSize, ""
    return blockSize
}

GetCHDCompression() {
    ; Get CHD compression codecs
    IniRead, compression, Settings.ini, CHD, Compression, cdlz,cdzl,cdfl
    return compression
}

GetCHDHunkSize() {
    ; Get CHD hunk size
    IniRead, hunkSize, Settings.ini, CHD, HunkSize, 19584
    return hunkSize
}

GetCHDProcessors() {
    ; Get number of processors for CHD
    IniRead, processors, Settings.ini, CHD, NumProcessors, 4
    return processors
}

; GUI Close event
MainGuiClose:
    SaveSettings()
    ExitApp

; GUI Escape event
MainGuiEscape:
    SaveSettings()
    ExitApp

; Create advanced options window
CreateAdvancedOptionsGUI() {
    Gui, Options:New, +Owner1 -MaximizeBox -MinimizeBox, Advanced Options
    
    ; CSO Options
    Gui, Options:Font, s10 Bold
    Gui, Options:Add, Text, x20 y20, CSO Compression Options:
    Gui, Options:Font, s9 Normal
    
    ; Threads
    Gui, Options:Add, Text, x30 y45, Threads:
    Gui, Options:Add, Edit, x100 y43 w50 h20 vCSOThreads
    Gui, Options:Add, Text, x160 y45, (1-16)
    
    ; Format
    Gui, Options:Add, Text, x30 y70, Format:
    Gui, Options:Add, DropDownList, x100 y68 w100 vCSOFormat, cso1||cso2|zso|dax
    
    ; Block Size
    Gui, Options:Add, Text, x30 y95, Block Size:
    Gui, Options:Add, Edit, x100 y93 w80 h20 vCSOBlockSize
    Gui, Options:Add, Text, x190 y95, (auto if empty)
    
    ; Compression methods
    Gui, Options:Add, CheckBox, x30 y120 vCSOUseZlib, Use Zlib compression
    Gui, Options:Add, CheckBox, x30 y140 vCSOUse7zip, Use 7-Zip deflate compression
    Gui, Options:Add, CheckBox, x30 y160 vCSOFastMode, Fast mode (lower quality)
    
    ; CHD Options
    Gui, Options:Font, s10 Bold
    Gui, Options:Add, Text, x20 y190, CHD Compression Options:
    Gui, Options:Font, s9 Normal
    
    ; Compression codecs
    Gui, Options:Add, Text, x30 y215, Compression:
    Gui, Options:Add, Edit, x120 y213 w150 h20 vCHDCompression
    
    ; Hunk Size
    Gui, Options:Add, Text, x30 y240, Hunk Size:
    Gui, Options:Add, Edit, x120 y238 w80 h20 vCHDHunkSize
    Gui, Options:Add, Text, x210 y240, (bytes)
    
    ; Processors
    Gui, Options:Add, Text, x30 y265, Processors:
    Gui, Options:Add, Edit, x120 y263 w50 h20 vCHDProcessors
    Gui, Options:Add, Text, x180 y265, (1-16)
    
    ; Buttons
    Gui, Options:Add, Button, x150 y300 w80 h30 gSaveOptions, Save
    Gui, Options:Add, Button, x240 y300 w80 h30 gCancelOptions, Cancel
    Gui, Options:Add, Button, x330 y300 w80 h30 gResetOptions, Reset
    
    ; Load current settings
    LoadOptionsGUI()
    
    return
}

; Load current settings into options GUI
LoadOptionsGUI() {
    GuiControl, Options:, CSOThreads, % GetCSOThreads()
    GuiControl, Options:Choose, CSOFormat, % GetCSOFormatIndex()
    GuiControl, Options:, CSOBlockSize, % GetCSOBlockSize()
    GuiControl, Options:, CSOUseZlib, % GetCSOUseZlib()
    GuiControl, Options:, CSOUse7zip, % GetCSOUse7zip()
    GuiControl, Options:, CSOFastMode, % GetCSOFastMode()
    
    GuiControl, Options:, CHDCompression, % GetCHDCompression()
    GuiControl, Options:, CHDHunkSize, % GetCHDHunkSize()
    GuiControl, Options:, CHDProcessors, % GetCHDProcessors()
}

; Get format index for dropdown
GetCSOFormatIndex() {
    format := GetCSOFormat()
    if (format = "cso1")
        return 1
    else if (format = "cso2")
        return 2
    else if (format = "zso")
        return 3
    else if (format = "dax")
        return 4
    else
        return 1
}

; Event handlers for options window
SaveOptions:
    Gui, Options:Submit, NoHide
    
    ; Save CSO options
    IniWrite, %CSOThreads%, Settings.ini, CSO, Threads
    IniWrite, % GetFormatFromIndex(CSOFormat), Settings.ini, CSO, Format
    IniWrite, %CSOBlockSize%, Settings.ini, CSO, BlockSize
    IniWrite, % (CSOUseZlib ? "yes" : "no"), Settings.ini, CSO, UseZlib
    IniWrite, % (CSOUse7zip ? "yes" : "no"), Settings.ini, CSO, Use7zip
    IniWrite, % (CSOFastMode ? "yes" : "no"), Settings.ini, CSO, FastMode
    
    ; Save CHD options
    IniWrite, %CHDCompression%, Settings.ini, CHD, Compression
    IniWrite, %CHDHunkSize%, Settings.ini, CHD, HunkSize
    IniWrite, %CHDProcessors%, Settings.ini, CHD, NumProcessors
    
    Gui, Options:Hide
    UpdateStatusBar("Advanced options saved")
return

CancelOptions:
    Gui, Options:Hide
return

ResetOptions:
    ; Reset to defaults
    GuiControl, Options:, CSOThreads, 4
    GuiControl, Options:Choose, CSOFormat, 1
    GuiControl, Options:, CSOBlockSize, 
    GuiControl, Options:, CSOUseZlib, 1
    GuiControl, Options:, CSOUse7zip, 1
    GuiControl, Options:, CSOFastMode, 0
    
    GuiControl, Options:, CHDCompression, cdlz,cdzl,cdfl
    GuiControl, Options:, CHDHunkSize, 19584
    GuiControl, Options:, CHDProcessors, 4
return

OptionsGuiClose:
    Gui, Options:Hide
return

; Helper function to get format from dropdown index
GetFormatFromIndex(index) {
    if (index = 1)
        return "cso1"
    else if (index = 2)
        return "cso2"
    else if (index = 3)
        return "zso"
    else if (index = 4)
        return "dax"
    else
        return "cso1"
}

; Event: Show advanced options
ShowAdvancedOptions:
    CreateAdvancedOptionsGUI()
    Gui, Options:Show, w450 h360, Advanced Options
return
