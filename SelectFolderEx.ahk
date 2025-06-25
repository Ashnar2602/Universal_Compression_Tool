; SelectFolderEx.ahk - Enhanced folder selection dialog
; Simplified folder selection for our universal compression tool

SelectFolderEx(StartingFolder := "", Prompt := "Select Folder", OwnerHWND := 0) {
    ; Use standard FileSelectFolder for simplicity
    FileSelectFolder, SelectedFolder, *%StartingFolder%, 3, %Prompt%
    return SelectedFolder
}
