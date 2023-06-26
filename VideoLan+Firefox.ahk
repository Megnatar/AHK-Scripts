#NoEnv
#SingleInstance force
#Persistent
#NoTrayIcon
#KeyHistory 0
ListLines off
SetBatchLines -1
SendMode Event
SetKeyDelay, 20, 1
SetWorkingDir C:\Program Files\VideoLAN\VLC\
DetectHiddenWindows on
SetTitleMatchMode 2

Global AppName = "vlc.exe"

if (!WinExist("ahk_exe " AppName)) {
    Run % AppName
    WinWait, % "ahk_exe " AppName
    
    new ShellHookWindow("vlc.exe")
}
Return

#IfWinExist ahk_exe vlc.exe
#IfWinActive ahk_exe vlc.exe
{
    ~Lbutton & rbutton::
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
    Return

    Mbutton up::
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
        Send, {LControl down}{ v }{LControl up}{Enter}
        KeyWait, Enter, L
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
    Return

    XButton1::
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
        Send, {LControl down}{ v }{LControl up}{tab}{tab}{Enter}
        KeyWait, Enter, L
        Send, {Enter}
        KeyWait, Enter, L
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
    Return

    XButton2::
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
        Send, {LControl down}{ y }{LControl up}
        KeyWait, LControl, L
        Send, {Enter}{tab}{Enter}
        KeyWait, Enter, L
        Send, {LControl down}{ h }{LControl up}
        KeyWait, Lcontrol, L
    Return

    #IfWinExist ahk_exe Firefox.exe
    #IfWinActive ahk_exe Firefox.exe
    {
        #IfWinNotActive ahk_exe vlc.exe
        ~Lbutton & Rbutton::
            Send, {Alt Down}{Down Down}
            KeyWait, Down, L D
            Send, {Alt Up}{Down Up} 
        Return
    }
    return
}
Return

Class ShellHookWindow
{
    __New(ThisExe) {
        This.OnExitApp := ThisExe
    }

    __Set(OnExitApp, ThisExe) {
        MessageID := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")
        
        DllCall("RegisterShellHookWindow", UInt, A_ScriptHwnd)
        OnMessage(MessageID, OnExitApp)
    }    
}

OnExitApp(wParam, lparam) {
    Static HSHELL_ACCESSIBILITYSTATE := 11, HSHELL_ACTIVATESHELLWINDOW := 3, HSHELL_APPCOMMAND := 12, HSHELL_GETMINRECT := 5, HSHELL_LANGUAGE := 8,
            HSHELL_REDRAW := 6 , HSHELL_TASKMAN := 7 , HSHELL_WINDOWACTIVATED := 4 , HSHELL_WINDOWCREATED := 1 , HSHELL_WINDOWDESTROYED := 2, HSHELL_WINDOWREPLACED := 13
    
    if (wParam = HSHELL_WINDOWDESTROYED && !WinExist("ahk_exe " AppName)) {
        DllCall("DeregisterShellHookWindow", UInt, A_ScriptHwnd)
        ExitApp
    } else {
        #IfWinExist ahk_exe vlc.exe
            Return
        #IfWinNotActive ahk_exe vlc.exe
            DllCall("DeregisterShellHookWindow", UInt, A_ScriptHwnd)
            ExitApp
    }
}
