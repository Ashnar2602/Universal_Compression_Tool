; ========================================
; IMPLEMENTAZIONI COMPLETE - File Management & Job Execution
; ========================================

; Gestione avanzata dei file
AddFilesToList(selectedFiles) {
    global
    
    ; Parse dei file selezionati (formato AutoHotkey per selezione multipla)
    StringSplit, fileArray, selectedFiles, `n
    baseDir := fileArray1
    
    ; Se è un singolo file
    if (fileArray0 = 1) {
        AddSingleFileToList(selectedFiles)
        return
    }
    
    ; File multipli
    Loop, %fileArray0% {
        if (A_Index = 1) {
            continue  ; Salta la directory base
        }
        
        fullPath := baseDir . "\" . fileArray%A_Index%
        AddSingleFileToList(fullPath)
    }
}

AddSingleFileToList(filePath) {
    global
    
    ; Verifica che il file non sia già nella lista
    for index, existingFile in INPUT_FILES {
        if (existingFile.path = filePath) {
            return  ; File già presente
        }
    }
    
    ; Ottieni informazioni file
    FileGetSize, fileSize, %filePath%
    fileSizeMB := Round(fileSize / 1024 / 1024, 2)
    
    SplitPath, filePath, fileName, fileDir, fileExt
    
    ; Verifica estensione supportata
    currentFormat := GetCurrentFormat()
    if (!IsExtensionSupported(fileExt, currentFormat.inputExts)) {
        MsgBox, 48, Warning, File type .%fileExt% is not supported for %currentFormat.name% compression.
        return
    }
    
    ; Aggiungi alla lista globale
    fileInfo := {path: filePath, name: fileName, size: fileSize, sizeMB: fileSizeMB, status: "Ready", ext: fileExt}
    INPUT_FILES.Push(fileInfo)
}

AddFolderToList(folderPath) {
    global
    
    currentFormat := GetCurrentFormat()
    
    ; Cerca file supportati nella cartella
    for index, ext in currentFormat.inputExts {
        searchPattern := folderPath . "\*." . ext
        
        Loop, Files, %searchPattern%
        {
            fullPath := A_LoopFileFullPath
            AddSingleFileToList(fullPath)
        }
    }
}

RefreshFileList() {
    global
    
    ; Pulisci ListView
    Gui, ListView, FileList
    LV_Delete()
    
    ; Aggiungi file alla ListView
    for index, fileInfo in INPUT_FILES {
        statusText := fileInfo.status
        LV_Add("", fileInfo.name, fileInfo.sizeMB . " MB", statusText)
    }
    
    ; Auto-ridimensiona colonne
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr") 
    LV_ModifyCol(3, "AutoHdr")
    
    ; Aggiorna status bar
    fileCount := INPUT_FILES.Length()
    SB_SetText("  Files: " . fileCount, 1)
}

RemoveFiles:
    Gui, ListView, FileList
    
    ; Rimuovi file selezionati (dal fondo verso l'alto per mantenere indici)
    Loop {
        rowNum := LV_GetNext()
        if (!rowNum) {
            break
        }
        
        ; Rimuovi dalla lista globale
        INPUT_FILES.RemoveAt(rowNum)
        
        ; Rimuovi dalla ListView
        LV_Delete(rowNum)
    }
    
    RefreshFileList()
return

ClearFiles:
    INPUT_FILES := []
    RefreshFileList()
return

BrowseOutput:
    FileSelectFolder, selectedFolder, *%OUTPUT_FOLDER%, 3, Select output folder
    if (!ErrorLevel && selectedFolder) {
        GuiControl,, OutputFolder, %selectedFolder%
        OUTPUT_FOLDER := selectedFolder
    }
return

; ========================================
; SISTEMA DI COMPRESSIONE ASINCRONO
; ========================================

StartCompressionJob() {
    global
    
    ; Validazione pre-compression
    if (!ValidateCompressionSettings()) {
        return
    }
    
    ; Disabilita controlli
    SetGUIState("compressing")
    
    ; Inizializza variabili job
    CURRENT_JOB_INDEX := 1
    TOTAL_JOBS := INPUT_FILES.Length()
    JOBS_COMPLETED := 0
    JOBS_FAILED := 0
    
    ; Avvia primo job
    ProcessNextFile()
}

ProcessNextFile() {
    global
    
    ; Controlla se abbiamo finito
    if (CURRENT_JOB_INDEX > TOTAL_JOBS) {
        OnCompressionComplete()
        return
    }
    
    ; Ottieni file corrente
    currentFile := INPUT_FILES[CURRENT_JOB_INDEX]
    
    ; Aggiorna status
    UpdateFileStatus(CURRENT_JOB_INDEX, "Processing...")
    
    ; Genera comando
    cmd := BuildCommandLineForFile(currentFile)
    
    ; Avvia processo asincrono
    RunAsync(cmd, "OnFileComplete")
}

BuildCommandLineForFile(fileInfo) {
    global
    
    ; Comando base
    cmd := BuildCommandLine()
    
    ; Aggiungi file input
    cmd .= " """ . fileInfo.path . """"
    
    ; Genera nome output
    GuiControlGet, outputFolder,, OutputFolder
    currentFormat := GetCurrentFormat()
    
    ; Cambia estensione
    SplitPath, % fileInfo.path, fileName, fileDir, fileExt
    StringTrimRight, baseName, fileName, % StrLen(fileExt) + 1
    outputFile := outputFolder . "\" . baseName . "." . currentFormat.defaultOutputExt
    
    ; Aggiungi parametro output se non è già gestito dal CLI
    cmd .= " --output=""" . outputFolder . """"
    
    return cmd
}

OnFileComplete(exitCode, output) {
    global
    
    ; Aggiorna status file corrente
    if (exitCode = 0) {
        UpdateFileStatus(CURRENT_JOB_INDEX, "Completed")
        JOBS_COMPLETED++
    } else {
        UpdateFileStatus(CURRENT_JOB_INDEX, "Failed")
        JOBS_FAILED++
        
        ; Log errore
        LogError("File " . INPUT_FILES[CURRENT_JOB_INDEX].name . " failed: " . output)
    }
    
    ; Aggiorna progress globale
    progress := Round((CURRENT_JOB_INDEX / TOTAL_JOBS) * 100)
    SB_SetText("  Progress: " . CURRENT_JOB_INDEX . "/" . TOTAL_JOBS . " (" . progress . "%)", 1)
    
    ; Passa al prossimo file
    CURRENT_JOB_INDEX++
    SetTimer, ProcessNextFile, -100  ; Piccolo delay per aggiornare UI
}

OnCompressionComplete() {
    global
    
    ; Riabilita controlli
    SetGUIState("ready")
    
    ; Mostra risultati
    completionMsg := "Compression completed!`n`n"
    completionMsg .= "Successful: " . JOBS_COMPLETED . "`n"
    completionMsg .= "Failed: " . JOBS_FAILED . "`n"
    completionMsg .= "Total: " . TOTAL_JOBS
    
    MsgBox, 64, Compression Complete, %completionMsg%
    
    ; Reset variabili
    CURRENT_JOB_INDEX := 0
    TOTAL_JOBS := 0
    JOBS_COMPLETED := 0
    JOBS_FAILED := 0
}

; ========================================
; GESTIONE STATO GUI
; ========================================

SetGUIState(state) {
    global
    
    if (state = "compressing") {
        ; Disabilita controlli durante compressione
        GuiControl, Disable, CompressionFormat
        GuiControl, Disable, BtnAddFiles
        GuiControl, Disable, BtnAddFolder
        GuiControl, Disable, BtnRemoveFiles
        GuiControl, Disable, BtnClearFiles
        GuiControl, Disable, BtnStart
        GuiControl, Show, BtnStop
        
        ; Disabilita anche i controlli delle opzioni
        DisableOptionsControls()
        
    } else if (state = "ready") {
        ; Riabilita controlli
        GuiControl, Enable, CompressionFormat
        GuiControl, Enable, BtnAddFiles
        GuiControl, Enable, BtnAddFolder
        GuiControl, Enable, BtnRemoveFiles
        GuiControl, Enable, BtnClearFiles
        GuiControl, Enable, BtnStart
        GuiControl, Hide, BtnStop
        
        ; Riabilita controlli opzioni
        EnableOptionsControls()
    }
}

DisableOptionsControls() {
    global
    
    currentFormat := GetCurrentFormat()
    if (!currentFormat) {
        return
    }
    
    for optionKey, optionData in currentFormat.options {
        controlName := optionKey . "_Control"
        GuiControl, Disable, %controlName%
    }
}

EnableOptionsControls() {
    global
    
    currentFormat := GetCurrentFormat()
    if (!currentFormat) {
        return
    }
    
    for optionKey, optionData in currentFormat.options {
        controlName := optionKey . "_Control"
        GuiControl, Enable, %controlName%
    }
}

UpdateFileStatus(fileIndex, status) {
    global
    
    ; Aggiorna lista globale
    INPUT_FILES[fileIndex].status := status
    
    ; Aggiorna ListView
    Gui, ListView, FileList
    LV_Modify(fileIndex, Col3, status)
    
    ; Colora riga basato su status
    if (status = "Completed") {
        ; Verde per completato (se supportato)
    } else if (status = "Failed") {
        ; Rosso per fallito (se supportato)
    }
}

; ========================================
; UTILITÀ E VALIDAZIONE
; ========================================

ValidateCompressionSettings() {
    global
    
    ; Controlla che ci siano file
    if (INPUT_FILES.Length() = 0) {
        MsgBox, 48, Error, Please add files to compress.
        return false
    }
    
    ; Controlla cartella output
    GuiControlGet, outputFolder,, OutputFolder
    if (!outputFolder) {
        MsgBox, 48, Error, Please select an output folder.
        return false
    }
    
    ; Crea cartella se non esistee
    if (!FileExist(outputFolder)) {
        FileCreateDir, %outputFolder%
        if (ErrorLevel) {
            MsgBox, 48, Error, Cannot create output folder: %outputFolder%
            return false
        }
    }
    
    ; Controlla che l'eseguibile CLI esista
    if (!FileExist(CLI_EXECUTABLE)) {
        MsgBox, 48, Error, CLI executable not found: %CLI_EXECUTABLE%`n`nPlease build the project first using build_cpp.bat
        return false
    }
    
    return true
}

IsExtensionSupported(ext, supportedExts) {
    for index, supportedExt in supportedExts {
        if (ext = supportedExt) {
            return true
        }
    }
    return false
}

LogError(message) {
    ; Log errori in file
    errorLog := A_ScriptDir . "\compression_errors.log"
    FileAppend, %A_Now%: %message%`n, %errorLog%
}

; ========================================
; PROCESSO ASINCRONO (Semplificato)
; ========================================

RunAsync(command, callbackFunction) {
    global ASYNC_CALLBACK := callbackFunction
    
    ; Per semplicità, usiamo RunWait con timer
    ; In una implementazione completa si userebbe Process e monitoraggio asincrono
    SetTimer, ExecuteCommand, -10
    
    ASYNC_COMMAND := command
}

ExecuteCommand:
    global
    
    ; Esegui comando e cattura output
    RunWait, %ASYNC_COMMAND%, %A_ScriptDir%, Hide, PID
    exitCode := ErrorLevel
    
    ; Chiama callback
    if (ASYNC_CALLBACK = "OnFileComplete") {
        OnFileComplete(exitCode, "")
    }
return

; ========================================
; GESTIONE EVENTI LISTVIEW
; ========================================

FileListEvents:
    if (A_GuiEvent = "DoubleClick") {
        ; Doppio click per aprire file
        selectedRow := LV_GetNext()
        if (selectedRow > 0) {
            filePath := INPUT_FILES[selectedRow].path
            Run, explorer.exe /select`,"%filePath%"
        }
    }
return

; ========================================
; STOP COMPRESSION
; ========================================

StopCompression:
    ; TODO: Implementare stop processo
    ; Per ora resettiamo lo stato
    SetGUIState("ready")
    
    ; Reset variabili job
    CURRENT_JOB_INDEX := 0
    TOTAL_JOBS := 0
    
    ; Aggiorna status file
    for index, fileInfo in INPUT_FILES {
        if (fileInfo.status = "Processing...") {
            UpdateFileStatus(index, "Cancelled")
        }
    }
    
    MsgBox, 64, Stopped, Compression stopped by user.
return
