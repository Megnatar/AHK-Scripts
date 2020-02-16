; Written by Megnatar.
;
; Autowalk v0.0.1. For all none isometric games.
; Everyone is free to use, add code or redistribute this script.
; But you MUST allway's credit ME Megnatar for creating it.
; 
; The source code for this script can be found on my Github repository:
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

ConfigFile := "Settings.ini"
Ss_Icon := 0x03

If (!FileExist(ConfigFile))
    IniWrite button1, %ConfigFile%, Settings, HKK

; Ini Read.
Loop, parse, % FileOpen(ConfigFile, 0).read(), `n, `r [
{							i := ResetVar-i
    i := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %i% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1), i := 0
}


Hotkey, *%HKK%, UserHotKey, on

Gui Add, GroupBox, x8 y0 w344 h162
Gui Add, Button, x24 y128 w80 h23, Start Game
Gui Add, GroupBox, x24 y16 w314 h73 +Center, Drop you're game executable here.
Gui Add, Button, x112 y128 w80 h23 gGuiClose, Exit
Gui Add, CheckBox, x208 y128 w120 h23, Run as admin
Gui Add, Edit, x72 y96 w128 h21 vHkey, %HKK%
Gui Add, Text, x24 y96 w44 h23, Hotkey:
Gui Add, Button, x208 y96 w80 h23 gNewKey, New Key
Gui Add, Picture, x40 y40 w32 h32 +%Ss_Icon% +AltSubmit +BackgroundTrans, %ExeFile%

Gui Show, w359 h171, AutoWalk
Return


GuiDropFiles:
Loop, parse, A_GuiEvent, `n, `r
    FullPath := A_LoopField, Path := SubStr(A_LoopField, 1, InStr(A_LoopField, "\", ,-1)-1), ExeFile := SubStr(A_LoopField, InStr(A_LoopField, "\", ,-1)+1)

IniWrite %FullPath%, %ConfigFile%, Settings, FullPath
IniWrite %Path%, %ConfigFile%, Settings, Path
IniWrite %ExeFile%, %ConfigFile%, Settings, ExeFile
Return

NewKey:
InputBox HKK, Change Hotkey, Type the name for the new key,, 384, 137
IniWrite %HKK%, %ConfigFile%, Settings, HKK
GuiControl, Text, Hkey, %HKK% 
Return

GuiEscape:
GuiClose:
ExitApp

#IfWinActive ExeFile

UserHotKey:
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

