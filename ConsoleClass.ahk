; ConsoleClass.ahk - Console management for compression processes
; Simplified console class for our universal compression tool

Class Console {
    __New(Title := "Console") {
        this.Title := Title
        this.Handle := 0
        return this
    }
    
    Show() {
        ; Show console window
        DllCall("AllocConsole")
        WinSetTitle, ahk_id %A_LastError%, , %this.Title%
        return true
    }
    
    Hide() {
        ; Hide console window
        DllCall("FreeConsole")
        return true
    }
    
    Write(Text) {
        ; Write text to console
        FileAppend, %Text%, CONOUT$
        return true
    }
    
    WriteLine(Text) {
        ; Write line to console
        this.Write(Text . "`n")
        return true
    }
}
