; Written by Megnatar.
;
; Autowalk v0.0.1. For all none isometric games.
; Everyone is free to use, add code and redistribute this script.
; But you MUST allway's credit ME Megnatar for creating the scource!
; 
; The scource code for this script can be found on my Github reposity:
;  https://github.com/Megnatar/AHK-Scripts

#NoEnv
#Persistent
#ErrorStdOut
#SingleInstance force
SetBatchLines, -1
SetTitleMatchMode, 3
SendMode, Event
SetKeyDelay, 5, 1
SetWorkingDir, %A_ScriptDir%

Global Wm_LbuttonDown:=0x201, Wm_Mousemove :=0x200, GettingKey := 0, BelowMouseOld, BelowMouse, ctrlTxt, CtrlIdCurrent, CtrlIdPrev, ConfigFile

ConfigFile  := "Settings.ini"
Ss_Icon     := 0x03
IsoCam      := 0
Admin       := 0

OnMessage(Wm_MouseMove, "MouseMessages")
OnMessage(Wm_LbuttonDown, "MouseMessages")


If (!FileExist(ConfigFile))
    IniWrite Xbutton1, %ConfigFile%, Settings, Hkey

; Ini Read.
ReadIni(ConfigFile)

if (Admin = 1 && !A_IsAdmin) {
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

Gui Add, GroupBox, x8 y0 w344 h162
Gui Add, Button, x24 y128 w80 h23 gRunGame, Start Game
Gui Add, GroupBox, x24 y16 w314 h73 +Center, Drop you're game executable here.
Gui Add, Picture, x40 y40 w32 h32 vPic +%Ss_Icon% +AltSubmit +BackgroundTrans, %FullPath%
Gui Add, Button, x112 y128 w80 h23 gGuiClose, Exit
Gui Add, Text, x24 y96 w44 h23, Hotkey:
Gui Add, Edit, x72 y96 w120 h21 Limit1 vHkey, %Hkey%
Gui Add, Text, x88 y48 w241 h23 +0x200 vTitle, %Title%
Gui Add, CheckBox, x208 y128 w120 h23 Checked%IsoCam% vIsoCam gIsoCam, Isomatric
Gui Add, CheckBox, x208 y96 w120 h23 Checked%Admin% vAdmin gAdmin, Run as admin
Gui Show, w359 h171, AutoWalk

if (IsoCam = 1) 
    GuiControl, Disable, Hkey
    
Hotkey, ~%Hkey%, UserHotKey, on
Return

IsoCam:
    GUI, submit, nohide
    if (IsoCam = 1) {
        GuiControl, , Hkey, Lbutton
        GuiControl, Disable, Hkey
        Hkey := "Lbutton"
        IniWrite, %Hkey%, %ConfigFile%, Settings, Hkey
    } else {
        GuiControl, enable, Hkey
    }
    IniWrite, %IsoCam%, %ConfigFile%, Settings, IsoCam
Return

Admin:
    GUI, submit, nohide
    IniWrite, %Admin%, %ConfigFile%, Settings, Admin
    if (Admin = 1) {
        Reload
    } else {
        ExitApp
    }
Return

GuiDropFiles:
    Loop, parse, A_GuiEvent, `n, `r
        FullPath := A_LoopField, Path := SubStr(A_LoopField, 1, InStr(A_LoopField, "\", ,-1)-1), ExeFile := SubStr(A_LoopField, InStr(A_LoopField, "\", ,-1)+1)
    IniWrite %FullPath%, %ConfigFile%, Settings, FullPath
    IniWrite %Path%, %ConfigFile%, Settings, Path
    IniWrite %ExeFile%, %ConfigFile%, Settings, ExeFile
    
    Title := ""
    GuiControl, , Title, %Title%
    IniWrite %Title%, %ConfigFile%, Settings, Title
    Reload
Return

GuiEscape:
GuiClose:
ExitApp

RunGame:
    If (!WinExist("ahk_exe " ExeFile)) {
        Run, %FullPath%, %Path%, , ProcessID
        WinWait, ahk_exe %ExeFile%, , , AutoWalk
        WinGet, HwndClient, ID, ahk_exe %ExeFile%
        ;Run "C:\Program Files\Cheat Engine 7.0\Cheat Engine.exe"
    } else {
        WinGet, hWndClient, ID, ahk_exe %ExeFile%, , AutoWalk
        WinGet, ProcessID, PID, ahk_exe %ExeFile%, , AutoWalk
        WinRestore, ahk_id %hWndClient%
        WinActivate, ahk_id %hWndClient%, , AutoWalk
    }

    ; Checks for any popup window and wait for it to close.
    WinGetClass, ClientGuiClass, ahk_exe %ExeFile%, , AutoWalk

    if InStr(ClientGuiClass, "Splash"){
        WinWaitClose, ahk_class %ClientGuiClass%, , , AutoWalk
        WinGetClass, ClientGuiClass, ahk_exe %ExeFile%, , AutoWalk
    }
    GroupAdd, ClientGroup, ahk_id %hWndClient%
    GroupAdd, ClientGroup, ahk_class %ClientGuiClass%
    
    If (!Title) {
        WinGetTitle, Title, ahk_exe %ExeFile%
        IniWrite %Title%, %ConfigFile%, Settings, Title
        GuiControl, , Title, %Title%
    }
    
Return

;______________________________________________________________________________________________________

ToggleKey(H := 0, S := 0, SndUp := 0) {
    static KeyState, sKey, hKey

    if (SndUp = 1 && KeyState = "Down") {
        Send, {%sKey% %KeyState%}
        return KeyState := "Up"
    }

    If (!hKey)
        sKey := S, hKey := H

    KeyState := KeyState != "Down" ? "Down" : "Up"

    If (hKey && sKey) {
        KeyWait, % hKey
        Send, {%sKey% %KeyState%}
    } else If ((hKey) & !(sKey)) {
        KeyWait, % hKey
        Send, {%hKey% %KeyState%}
    }
    return KeyState
}

KeyWait(K := "", O := "", ErrLvL := "") {
    keywait, % Key := K ? K : RegExReplace(A_ThisHotkey, "[~\*\$]"), % O
    Return ErrLvL = 1 ? ErrorLevel : Key
}

; GuiControl is made a function.
GuiControl(ControlID, P:="", cmd:="") {
    InStr(CtrlIdCurrent, "Tmr")
        GuiControl, %cmd%, %ControlID%, %P%
    return % ""
}

MouseMessages(wParam, lParam, msg, hWnd) {
    Static ClsNNPrevious, ClsNNCurrent, ;, BelowMouse, BelowMouseOld
    
    ClsNNPrevious := ClsNNCurrent
    MouseGetPos, , , , ClsNNCurrent
    BelowMouse := ClsNNCurrent
    CtrlIdPrev := CtrlIdCurrent
    CtrlIdCurrent := A_GuiControl
    
    if (ClsNNPrevious != ClsNNCurrent) {
        BelowMouseOld := ClsNNPrevious
    }
    
    if (msg = Wm_LbuttonDown) {
        If (BelowMouse = "Edit1" && GettingKey = 0) {
            ControlFocus, %BelowMouse%
            ControlGetText, ctrlTxt, %BelowMouse%
            GuiControl +gEditGetKey, %CtrlIdCurrent%
            Send, ^a{bs}
            GuiControl -gEditGetKey, %CtrlIdCurrent%
            
            
        }
    }
}

; Writes back the name of any keyboard, mouse or joystic button to a edit control.
EditGetKey() {
    static InputKeys := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9","Numpad10","NumpadEnter", "NumpadAdd", "NumpadSub","NumpadMult", "NumpadDev", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "Left", "Right", "Up", "Down", "Home","End", "PgUp", "PgDn", "Del", "Ins", "Capslock", "Numlock", "PrintScreen", "Pause", "LControl", "RControl", "LAlt", "RAlt", "LShift","RShift", "LWin", "RWin", "AppsKey", "BackSpace", "space", "Tab", "Esc", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n","o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "/", "[", "]", "\", "'", ";", "` ","Joy1", "Joy2", "Joy3", "Joy4", "Joy5", "Joy6", "Joy7", "Joy8", "Joy9", "Joy10", "Joy11", "Joy12", "Joy13", "Joy14", "Joy15", "Joy16", "Joy17","Joy18", "Joy19", "Joy20", "Joy21", "Joy22", "Joy23", "Joy24", "Joy25", "Joy26", "Joy27", "Joy28", "Joy29", "Joy30","Joy31", "Joy32"]
    GuiControl -gEditGetKey, %CtrlIdCurrent%
    
    KeyWait("Lbutton")
    GettingKey := 1
    Hotkey, IfWinExist, AutoWalk
    Hotkey, Rbutton Up, RbttnUp, On
    loop {
        For i, ThisKey in InputKeys {
            if GetKeyState(ThisKey, "P") {
                GuiControl, , Hkey, %ThisKey%
                KeyWait(ThisKey)
                Key := ThisKey
                Break
            }
            If (CtrlIdCurrent != "Hkey") {
                GuiControl, , Hkey, %ctrlTxt%
                Key := 1
                Break
            }
        }
        If (Key)  
            break
    }
    GettingKey := 0
    ControlFocus, Button1
    send {Tab}
    If (Key != 1)  
        IniWrite, %ThisKey%, %ConfigFile%, Settings, Hkey
    GUI, submit, nohide
    
    RbttnUp:
    Hotkey, IfWinExist, AutoWalk
    Hotkey, Rbutton Up, RbttnUp, Off
    return
}

ReadIni(InputFile, LoadSection=0, ExcludeSection*) {  
    local TmpVar, SectionFound, S := []
    If (LoadSection) {
        Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
        {
            if (((!SectionFound) = 1 ? (SectionFound := (InStr(A_LoopField, LoadSection)) > 0 ? 1 : "")) || ((InStr(A_LoopField, "[")) = 1 ? 1)) {
                Continue 
            } 
            else if (SectionFound) {
                if ((InStr(A_LoopField, "[")) = 1 ? 1 : "") {
                    Break 
                } 
                else if (((InStr(A_LoopField, "`;")) = 1 ? 1) || !A_LoopField) {
                    Continue
                }
                S[SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1)] := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
            }
        }
       return S
    }

    Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
    {
        if (((InStr(A_LoopField, "[")) = 1 ? 1) || ((InStr(A_LoopField, "`;")) = 1 ? 1) || !A_LoopField)
            Continue
            
        TmpVar := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %TmpVar% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
    }                                                              
}

AutoTurncamera(K, Rl, Rr) {
    WinGetActiveStats, Title, Width, Height, X, Y
    Rad := 180 / 3.1415926
    
    While(GetKeyState(K, "P")) {
        MouseGetPos, xpos, ypos
        xpos := xpos - Width/2, ypos := Height/2 - ypos

        if ((xpos*xpos + ypos*ypos < 10000) || ((ypos > 0) && (Abs(ATan(xpos / ypos)) * Rad < 20)))
            continue

        if (xpos > 0) {
            Send {%Rr% down}
            Sleep, 10
            Send {%Rr% up}
        } else {
            Send {%Rl% down}
            Sleep, 10
            Send {%Rl% up}
        }
    }
}

#IfWinActive, ahk_group ClientGroup

UserHotKey:
    If (IsoCam = 1) {
        If (KeyWait("Lbutton", "T0.200", 1) = 0) {
            If (KeyWait("Lbutton", "D T0.200", 1) = 0) {
                keywait("Lbutton")
                KeyState := KeyState != "down" ? "down" : "up"
                Send, {Lbutton %KeyState%}
            } else {
                Send, {Lbutton up}
                KeyState = up
            }
        } else {
            ; ....
        }
        Return
    }

    State := ToggleKey(RegExReplace(A_ThisHotkey, "[\*\$~]"), "w")

    if (State = "Down") {
        Hotkey, W, InterruptDownState, ON
        Hotkey, Lbutton, InterruptDownState, ON
    } else if (State = "Up") {
        Hotkey, w, InterruptDownState, OFF
        Hotkey, Lbutton, InterruptDownState, OFF
    }
Return

InterruptDownState:
    if (A_ThisHotkey = "w")
        KeyWait("w")

    State := ToggleKey(,,"1")

    Hotkey, W, InterruptDownState, OFF
    Hotkey, Lbutton, InterruptDownState, OFF
return
