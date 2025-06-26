; ========================================
; JOB PROCESSING ENGINE
; Sistema scalabile per l'elaborazione batch
; ========================================

; ========================================
; STRUTTURE DATI JOB
; ========================================

; Job queue globale
JOB_QUEUE := []
ACTIVE_JOBS := {}
JOB_HISTORY := []

; Stati job
JOB_STATUS := {
    PENDING: "Pending",
    RUNNING: "Running", 
    COMPLETED: "Completed",
    FAILED: "Failed",
    CANCELLED: "Cancelled"
}

; Statistiche globali
JOB_STATS := {
    totalJobs: 0,
    completedJobs: 0,
    failedJobs: 0,
    totalInputSize: 0,
    totalOutputSize: 0,
    totalTimeSpent: 0
}

; ========================================
; CLASSE JOB
; ========================================

class CompressionJob {
    
    __New(inputFile, outputFile, formatKey, options := {}) {
        this.id := this.GenerateJobID()
        this.inputFile := inputFile
        this.outputFile := outputFile
        this.formatKey := formatKey
        this.options := options
        this.status := JOB_STATUS.PENDING
        this.progress := 0
        this.startTime := ""
        this.endTime := ""
        this.duration := 0
        this.inputSize := 0
        this.outputSize := 0
        this.compressionRatio := 0
        this.errorMessage := ""
        this.command := ""
        this.processID := 0
        this.tempFiles := []
        
        ; Calculate input size
        if (FileExist(this.inputFile)) {
            FileGetSize, size, % this.inputFile
            this.inputSize := size
        }
        
        ; Build CLI command
        this.command := BuildCLICommand(this.formatKey, this.inputFile, this.outputFile, this.options)
    }
    
    GenerateJobID() {
        ; Generate unique job ID
        Random, rand, 1000, 9999
        return A_TickCount . "_" . rand
    }
    
    Start() {
        global ACTIVE_JOBS
        
        this.status := JOB_STATUS.RUNNING
        this.startTime := A_Now
        this.progress := 0
        
        ; Add to active jobs
        ACTIVE_JOBS[this.id] := this
        
        ; Log start
        LogFormatOperation(this.formatKey, "Job Started", "ID: " . this.id . ", File: " . this.inputFile)
        
        ; Execute CLI command
        try {
            this.ExecuteCommand()
            return true
        } catch e {
            this.Fail("Failed to start process: " . e.message)
            return false
        }
    }
    
    ExecuteCommand() {
        ; Create console instance for process monitoring
        this.console := new Console(this.command)
        this.console.onData := ObjBindMethod(this, "OnProcessOutput")
        this.console.onExit := ObjBindMethod(this, "OnProcessExit")
        
        ; Start process
        this.processID := this.console.Start()
        
        if (this.processID == 0) {
            throw Exception("Failed to start CLI process")
        }
    }
    
    OnProcessOutput(data) {
        ; Parse output for progress information
        this.ParseProgressFromOutput(data)
        
        ; Update GUI if needed
        UpdateJobProgress(this.id, this.progress)
    }
    
    OnProcessExit(exitCode) {
        global ACTIVE_JOBS
        
        ; Remove from active jobs
        ACTIVE_JOBS.Delete(this.id)
        
        this.endTime := A_Now
        this.CalculateDuration()
        
        if (exitCode == 0) {
            this.Complete()
        } else {
            this.Fail("Process exited with code: " . exitCode)
        }
    }
    
    ParseProgressFromOutput(output) {
        ; Parse CLI output for progress information
        ; This would depend on the specific output format of the CLI tool
        
        ; Example parsing patterns:
        if (RegexMatch(output, "Progress:\s*(\d+)%", match)) {
            this.progress := match1
        } else if (RegexMatch(output, "\[(\d+)/(\d+)\]", match)) {
            this.progress := Round((match1 / match2) * 100)
        }
        
        ; Ensure progress is within bounds
        if (this.progress > 100) {
            this.progress := 100
        }
    }
    
    Complete() {
        global JOB_HISTORY, JOB_STATS
        
        this.status := JOB_STATUS.COMPLETED
        this.progress := 100
        
        ; Calculate output size and compression ratio
        if (FileExist(this.outputFile)) {
            FileGetSize, size, % this.outputFile
            this.outputSize := size
            
            if (this.inputSize > 0) {
                this.compressionRatio := Round((1 - this.outputSize / this.inputSize) * 100, 2)
            }
        }
        
        ; Update statistics
        JOB_STATS.completedJobs++
        JOB_STATS.totalOutputSize += this.outputSize
        JOB_STATS.totalTimeSpent += this.duration
        
        ; Add to history
        JOB_HISTORY.Push(this)
        
        ; Log completion
        LogFormatOperation(this.formatKey, "Job Completed", 
            "ID: " . this.id . ", Ratio: " . this.compressionRatio . "%, Time: " . this.duration . "s")
        
        ; Cleanup temp files
        this.CleanupTempFiles()
        
        ; Notify UI
        OnJobCompleted(this)
    }
    
    Fail(errorMessage) {
        global JOB_HISTORY, JOB_STATS
        
        this.status := JOB_STATUS.FAILED
        this.errorMessage := errorMessage
        
        ; Update statistics
        JOB_STATS.failedJobs++
        
        ; Add to history
        JOB_HISTORY.Push(this)
        
        ; Log failure
        LogFormatOperation(this.formatKey, "Job Failed", 
            "ID: " . this.id . ", Error: " . errorMessage)
        
        ; Cleanup temp files
        this.CleanupTempFiles()
        
        ; Notify UI
        OnJobFailed(this)
    }
    
    Cancel() {
        global ACTIVE_JOBS
        
        if (this.processID > 0) {
            ; Terminate process
            Process, Close, % this.processID
            this.processID := 0
        }
        
        this.status := JOB_STATUS.CANCELLED
        this.endTime := A_Now
        this.CalculateDuration()
        
        ; Remove from active jobs
        ACTIVE_JOBS.Delete(this.id)
        
        ; Cleanup temp files
        this.CleanupTempFiles()
        
        ; Log cancellation
        LogFormatOperation(this.formatKey, "Job Cancelled", "ID: " . this.id)
        
        ; Notify UI
        OnJobCancelled(this)
    }
    
    CalculateDuration() {
        if (this.startTime != "" && this.endTime != "") {
            startTime := this.startTime
            endTime := this.endTime
            
            ; Convert to seconds
            EnvSub, endTime, %startTime%, Seconds
            this.duration := endTime
        }
    }
    
    CleanupTempFiles() {
        ; Clean up any temporary files created during processing
        for index, tempFile in this.tempFiles {
            if (FileExist(tempFile)) {
                FileDelete, %tempFile%
            }
        }
        this.tempFiles := []
    }
    
    GetStatusText() {
        statusText := this.status
        
        if (this.status == JOB_STATUS.RUNNING && this.progress > 0) {
            statusText .= " (" . this.progress . "%)"
        } else if (this.status == JOB_STATUS.COMPLETED && this.compressionRatio > 0) {
            statusText .= " (-" . this.compressionRatio . "%)"
        } else if (this.status == JOB_STATUS.FAILED && this.errorMessage != "") {
            statusText .= " - " . this.errorMessage
        }
        
        return statusText
    }
}

; ========================================
; JOB QUEUE MANAGER
; ========================================

class JobQueueManager {
    
    static instance := ""
    
    __New() {
        this.maxConcurrentJobs := 2
        this.isProcessing := false
        this.isPaused := false
    }
    
    static GetInstance() {
        if (JobQueueManager.instance == "") {
            JobQueueManager.instance := new JobQueueManager()
        }
        return JobQueueManager.instance
    }
    
    AddJob(inputFile, outputFile, formatKey, options := {}) {
        global JOB_QUEUE, JOB_STATS
        
        ; Create new job
        job := new CompressionJob(inputFile, outputFile, formatKey, options)
        
        ; Add to queue
        JOB_QUEUE.Push(job)
        
        ; Update statistics
        JOB_STATS.totalJobs++
        JOB_STATS.totalInputSize += job.inputSize
        
        ; Log addition
        LogFormatOperation(formatKey, "Job Added", "ID: " . job.id . ", Queue position: " . JOB_QUEUE.Length())
        
        ; Start processing if not already running
        if (!this.isProcessing) {
            this.StartProcessing()
        }
        
        return job.id
    }
    
    StartProcessing() {
        if (this.isProcessing || this.isPaused) {
            return
        }
        
        this.isProcessing := true
        
        ; Start processing timer
        SetTimer, ProcessJobQueue, 1000
        
        ; Notify UI
        OnQueueProcessingStarted()
    }
    
    StopProcessing() {
        global ACTIVE_JOBS
        
        this.isProcessing := false
        
        ; Stop processing timer
        SetTimer, ProcessJobQueue, Off
        
        ; Cancel all active jobs
        for jobID, job in ACTIVE_JOBS {
            job.Cancel()
        }
        
        ; Notify UI
        OnQueueProcessingStopped()
    }
    
    PauseProcessing() {
        this.isPaused := true
        OnQueueProcessingPaused()
    }
    
    ResumeProcessing() {
        this.isPaused := false
        if (!this.isProcessing) {
            this.StartProcessing()
        }
        OnQueueProcessingResumed()
    }
    
    ProcessQueue() {
        global JOB_QUEUE, ACTIVE_JOBS
        
        if (this.isPaused || !this.isProcessing) {
            return
        }
        
        ; Check if we can start more jobs
        currentActiveJobs := ACTIVE_JOBS.Count()
        
        if (currentActiveJobs >= this.maxConcurrentJobs) {
            return ; Already at max capacity
        }
        
        ; Start next pending job
        if (JOB_QUEUE.Length() > 0) {
            job := JOB_QUEUE.RemoveAt(1)
            job.Start()
        } else if (currentActiveJobs == 0) {
            ; No more jobs to process
            this.StopProcessing()
            OnAllJobsCompleted()
        }
    }
    
    GetQueueStatus() {
        global JOB_QUEUE, ACTIVE_JOBS
        
        return {
            queueLength: JOB_QUEUE.Length(),
            activeJobs: ACTIVE_JOBS.Count(),
            isProcessing: this.isProcessing,
            isPaused: this.isPaused
        }
    }
    
    SetMaxConcurrentJobs(maxJobs) {
        this.maxConcurrentJobs := maxJobs
    }
    
    ClearQueue() {
        global JOB_QUEUE
        
        ; Cancel pending jobs
        JOB_QUEUE := []
        
        ; Notify UI
        OnQueueCleared()
    }
    
    GetJobByID(jobID) {
        global JOB_QUEUE, ACTIVE_JOBS, JOB_HISTORY
        
        ; Check active jobs
        if (ACTIVE_JOBS.hasKey(jobID)) {
            return ACTIVE_JOBS[jobID]
        }
        
        ; Check queue
        for index, job in JOB_QUEUE {
            if (job.id == jobID) {
                return job
            }
        }
        
        ; Check history
        for index, job in JOB_HISTORY {
            if (job.id == jobID) {
                return job
            }
        }
        
        return ""
    }
}

; ========================================
; TIMER FUNCTIONS
; ========================================

ProcessJobQueue:
    queueManager := JobQueueManager.GetInstance()
    queueManager.ProcessQueue()
return

; ========================================
; EVENT HANDLERS (per la GUI)
; ========================================

OnJobCompleted(job) {
    ; Update file list in GUI
    UpdateFileListJobStatus(job.inputFile, job.status, job.progress)
    
    ; Update statistics display
    RefreshStatisticsDisplay()
    
    ; Play completion sound if enabled
    if (SETTINGS.playCompletionSound) {
        SoundPlay, %A_WinDir%\Media\Windows Ding.wav
    }
}

OnJobFailed(job) {
    ; Update file list in GUI
    UpdateFileListJobStatus(job.inputFile, job.status, 0)
    
    ; Show error notification
    if (SETTINGS.showErrorNotifications) {
        TrayTip, Compression Failed, %job.errorMessage%, 5, 3
    }
    
    ; Update statistics display
    RefreshStatisticsDisplay()
}

OnJobCancelled(job) {
    ; Update file list in GUI
    UpdateFileListJobStatus(job.inputFile, job.status, 0)
    
    ; Update statistics display
    RefreshStatisticsDisplay()
}

OnQueueProcessingStarted() {
    ; Update GUI controls
    GuiControl, Disable, BtnStart
    GuiControl, Show, BtnStop
    GuiControl, Enable, BtnStop
    
    ; Update status bar
    SB_SetText("Processing jobs...", 1)
}

OnQueueProcessingStopped() {
    ; Update GUI controls
    GuiControl, Enable, BtnStart
    GuiControl, Hide, BtnStop
    
    ; Update status bar
    SB_SetText("Ready", 1)
}

OnQueueProcessingPaused() {
    SB_SetText("Paused", 1)
}

OnQueueProcessingResumed() {
    SB_SetText("Processing jobs...", 1)
}

OnAllJobsCompleted() {
    global JOB_STATS
    
    ; Show completion summary
    totalFiles := JOB_STATS.completedJobs + JOB_STATS.failedJobs
    
    if (totalFiles > 0) {
        summaryText := "Processing completed!`n`n"
        summaryText .= "Total files: " . totalFiles . "`n"
        summaryText .= "Successful: " . JOB_STATS.completedJobs . "`n"
        summaryText .= "Failed: " . JOB_STATS.failedJobs . "`n"
        
        if (JOB_STATS.totalInputSize > 0 && JOB_STATS.totalOutputSize > 0) {
            totalRatio := Round((1 - JOB_STATS.totalOutputSize / JOB_STATS.totalInputSize) * 100, 2)
            summaryText .= "Total compression: " . totalRatio . "%`n"
            summaryText .= "Space saved: " . FormatBytes(JOB_STATS.totalInputSize - JOB_STATS.totalOutputSize) . "`n"
        }
        
        summaryText .= "Total time: " . FormatTime(JOB_STATS.totalTimeSpent)
        
        MsgBox, 64, Processing Complete, %summaryText%
    }
    
    ; Update status bar
    SB_SetText("All jobs completed", 1)
}

OnQueueCleared() {
    ; Update GUI
    RefreshStatisticsDisplay()
    SB_SetText("Queue cleared", 1)
}

; ========================================
; UTILITY FUNCTIONS
; ========================================

UpdateJobProgress(jobID, progress) {
    ; Update progress in file list
    Gui, ListView, FileList
    
    ; Find the row for this job
    Loop % LV_GetCount() {
        LV_GetText, fileName, A_Index, 1
        
        ; Match by filename (this could be improved with better tracking)
        job := JobQueueManager.GetInstance().GetJobByID(jobID)
        if (job != "") {
            SplitPath, % job.inputFile, currentFileName
            if (fileName == currentFileName) {
                LV_Modify(A_Index, Col5, progress . "%")
                break
            }
        }
    }
}

UpdateFileListJobStatus(inputFile, status, progress) {
    ; Update status in file list
    Gui, ListView, FileList
    
    SplitPath, inputFile, fileName
    
    ; Find the row for this file
    Loop % LV_GetCount() {
        LV_GetText, currentFileName, A_Index, 1
        if (currentFileName == fileName) {
            LV_Modify(A_Index, Col4, status)
            LV_Modify(A_Index, Col5, progress . "%")
            break
        }
    }
}

RefreshStatisticsDisplay() {
    global JOB_STATS
    
    ; Update status bar with current statistics
    totalJobs := JOB_STATS.completedJobs + JOB_STATS.failedJobs
    SB_SetText("Completed: " . JOB_STATS.completedJobs . "/" . totalJobs, 2)
    
    ; Update queue info
    queueStatus := JobQueueManager.GetInstance().GetQueueStatus()
    SB_SetText("Queue: " . queueStatus.queueLength, 4)
}

FormatTime(seconds) {
    hours := Floor(seconds / 3600)
    minutes := Floor((seconds - hours * 3600) / 60)
    seconds := Mod(seconds, 60)
    
    if (hours > 0) {
        return hours . "h " . minutes . "m " . seconds . "s"
    } else if (minutes > 0) {
        return minutes . "m " . seconds . "s"
    } else {
        return seconds . "s"
    }
}

; ========================================
; BATCH OPERATIONS
; ========================================

StartBatchCompression(fileList, outputFolder, formatKey, options) {
    queueManager := JobQueueManager.GetInstance()
    
    addedJobs := []
    
    for index, fileInfo in fileList {
        ; Generate output filename
        SplitPath, % fileInfo.path, fileName, , fileExt
        
        ; Get default output extension for format
        global COMPRESSION_FORMATS
        if (COMPRESSION_FORMATS.hasKey(formatKey)) {
            outputExt := COMPRESSION_FORMATS[formatKey].defaultOutputExt
            outputFile := outputFolder . "\" . StrReplace(fileName, "." . fileExt, "." . outputExt)
            
            ; Add job to queue
            jobID := queueManager.AddJob(fileInfo.path, outputFile, formatKey, options)
            addedJobs.Push(jobID)
        }
    }
    
    return addedJobs
}

; ========================================
; ESEMPI DI UTILIZZO
; ========================================

/*
Esempio 1: Avviare compressione batch

files := [
    {path: "C:\Games\game1.iso"},
    {path: "C:\Games\game2.iso"}
]

jobIDs := StartBatchCompression(files, "C:\Compressed", "CSO", {
    format: "cso1",
    threads: 4,
    fastMode: false
})

Esempio 2: Monitorare job specifico

queueManager := JobQueueManager.GetInstance()
job := queueManager.GetJobByID(jobIDs[1])

if (job != "") {
    MsgBox, Job status: %job.status%, Progress: %job.progress%%
}

Esempio 3: Controllare la queue

queueManager.SetMaxConcurrentJobs(4)  ; Allow 4 concurrent jobs
queueManager.PauseProcessing()        ; Pause processing
queueManager.ResumeProcessing()       ; Resume processing
queueManager.StopProcessing()         ; Stop all processing

*/
