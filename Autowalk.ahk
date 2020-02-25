/*
    Written by Megnatar.

    Autowalk v0.9.0.
    Everyone is free to use, add code and redistribute this script.
    But you MUST always credit ME Megnatar for creating the source!
 
    The source code for this script can be found on my Github repository:
    https://github.com/Megnatar/AHK-Scripts
    
    Usage:
    To add a new game, just drop the executable on the gui.
    IMPORTANT: This will NOT work when the script is started in admin mode.
    
    Click in a edit box to set a new hotkey. Any key will do, the script will write 
    the name of the key eg Xbutton2, if you pressed it, back to the edit control. 
    This key will be the hotkey that will enable autowalking.
    
    Enable the checkbox "RPG Games" for games with a isomatric camera (Top down view).
    Lbutton will be automatically send down when you double click the left mouse button.
    Click again to stop. 
    
    When the camera does not automatically follow the player enable "Turn camera" and
    set the two keys used by the game to rotate the camera left or right.
    A double click will now also enable auto rotation of the camera.
    
    If the game does not accept input. Then enable admin mode and try again!
    
*/
#NoEnv
#Persistent
#SingleInstance ignore
#KeyHistory 0
;ListLines off
SetBatchLines -1
SetTitleMatchMode 3
SetKeyDelay 5, 1
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On

Global Wm_LbuttonDown:=0x201, Wm_Mousemove :=0x200, InputActive := 0, CtrlClassMousePreviouse, CtrlClassMouseCurrent, ctrlTxt, CtrlIdCurrent, CtrlIdPrev, ConfigFile

ConfigFile  := "Settings.ini"
IsoCam      := 0
Admin       := 0
TurnCamera  := 0
LeftKey     :=  "Left"
RightKey    :=  "Right"

If (!FileExist(ConfigFile))
    IniWrite Xbutton1, %ConfigFile%, Settings, Hkey

ReadIni(ConfigFile)

if (Admin = 1 && !A_IsAdmin) {
    Try {
        if (A_IsCompiled) {
            Run, *RunAs "%A_ScriptFullPath%"
        } else {
            Run, *RunAs "%A_AhkPath%" /ErrorStdOut "%A_ScriptFullPath%"
        }
    } Catch ThisError {
        MsgBox % ThisError
    }
    ExitApp
}

Gui Add, GroupBox, x8 y0 w353 h171
Gui Add, GroupBox, x16 y8 w336 h64 +Center, Drop you're game executable here.
Gui Add, Picture, x24 y16 w48 h48 0x6 0x0003 +AltSubmit +BackgroundTrans vPic, %FullPath%
Gui Add, Text, x80 y32 w256 h23 +0x200 vTitle, %Title%
Gui Add, Button, x16 y136 w80 h23 vRunGame gRunGame, &Start Game
Gui Add, Button, x104 y136 w80 h23 gOpenFolder, Open folder
Gui Add, Button, x272 y136 w80 h23 gGuiClose, Exit
Gui Add, GroupBox, x16 y72 w336 h59
Gui Add, Text, x24 y88 w44 h23, Hotkey:
Gui Add, Edit, x64 y88 w63 h21 Limit1 vHkey, %Hkey%
Gui Add, CheckBox, x136 y80 w77 h23 Checked%IsoCam% vIsoCam gIsoCam, RPG Games
Gui Add, CheckBox, x136 y104 w77 h23 +Disabled Checked%TurnCamera% vTurnCamera gTurnCamera, TurnCamera
Gui Add, CheckBox, x216 y80 w83 h23 Checked%Admin% vAdmin gAdmin, Run as admin
Gui Add, Edit, x216 y104 w60 h21 +Disabled Limit1 vLeftKey, %LeftKey%
Gui Add, Edit, x279 y104 w60 h21 +Disabled Limit1 vRightKey, %RightKey%
Gui Show, w370 h179, AutoWalk

if (IsoCam = 1) {
    GuiControl, Disable, Hkey
    GuiControl, Enable, TurnCamera
    
    if (TurnCamera = 1) {
        GuiControl, Enable, LeftKey
        GuiControl, Enable, RightKey    
    }    
}
  
Hotkey, ~%Hkey%, UserHotKey, on

OnMessage(Wm_MouseMove, "WM_Mouse"), OnMessage(Wm_LbuttonDown, "WM_Mouse")
Return

IsoCam:
    GUI, submit, nohide
    if (IsoCam = 1) {
        Hkey := "Lbutton"
        
        GuiControl, , Hkey, Lbutton
        GuiControl, Disable, Hkey
        GuiControl, Enable, TurnCamera
        IniWrite, %Hkey%, %ConfigFile%, Settings, Hkey
    } else {
        TurnCamera := 0
        
        GuiControl, enable, Hkey
        GuiControl, Disable, TurnCamera
        GuiControl, Disable, LeftKey
        GuiControl, Disable, RightKey
        GuiControl, , TurnCamera, 0
        IniWrite, %TurnCamera%, %ConfigFile%, Settings, TurnCamera
    }
    IniWrite, %IsoCam%, %ConfigFile%, Settings, IsoCam
Return

TurnCamera:
    GUI, submit, nohide
    if (TurnCamera = 1) {
        GuiControl, Enable, LeftKey
        GuiControl, Enable, RightKey
    } else {
        GuiControl, Disable, LeftKey
        GuiControl, Disable, RightKey
    }
    IniWrite, %TurnCamera%, %ConfigFile%, Settings, TurnCamera
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

RunGame:
    If (!WinExist("ahk_exe " ExeFile)) {
        Run, %FullPath%, %Path%, , ProcessID
        WinWaitActive, ahk_exe %ExeFile%, , , AutoWalk
        WinGet, HwndClient, ID, ahk_exe %ExeFile%
    } else {
        WinGet, WinStat, MinMax, ahk_exe %ExeFile%, , AutoWalk
        WinGet, hWndClient, ID, ahk_exe %ExeFile%, , AutoWalk
        WinGet, ProcessID, PID, ahk_exe %ExeFile%, , AutoWalk
        
        if (WinStat = -1) 
            WinRestore, ahk_id %hWndClient%, , AutoWalk
        else
            WinActivate, ahk_id %hWndClient%, , AutoWalk
    }

    WinGetClass, ClientGuiClass, ahk_exe %ExeFile%, , AutoWalk
    
    ; Checks for any popup window and wait for it to close.
    if InStr(ClientGuiClass, "Splash"){
        WinWaitClose, ahk_class %ClientGuiClass%, , , AutoWalk
        WinGetClass, ClientGuiClass, ahk_exe %ExeFile%, , AutoWalk
        WinGet, HwndClient, ID, ahk_exe %ExeFile%
    }
    GroupAdd, ClientGroup, ahk_id %hWndClient%
    GroupAdd, ClientGroup, ahk_class %ClientGuiClass%
    
    If (!Title) {
        WinGetTitle, Title, ahk_exe %ExeFile%
        IniWrite %Title%, %ConfigFile%, Settings, Title
        GuiControl, , Title, %Title%
    }
Return

OpenFolder:
    Run, Explorer.exe "%Path%"
Return

GuiEscape:
GuiClose:
ExitApp

;_______________________________________ Script Functions _______________________________________

; Toggle some key down or up.
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
        KeyWait(hKey)
        Send, {%sKey% %KeyState%}
    } else If ((hKey) & !(sKey)) {
        KeyWait(hKey)
        Send, {%hKey% %KeyState%}
    }
    return KeyState
}

; KeyWait as a function for more flexible usage.
KeyWait(K := "", O := "", ErrLvL := "") {
    keywait, % Key := K ? K : RegExReplace(A_ThisHotkey, "[~\*\$]"), % O
    Return ErrLvL = 1 ? ErrorLevel : Key
}

; Keep track of mouse movement and left click inside the gui.
WM_Mouse(wParam, lParam, msg, hWnd) {
    Static ClsNNPrevious, ClsNNCurrent, X, Y

    ;X := HIWORD(LPARAM), Y := LOWORD(LPARAM)
    
    ; ClsNNPrevious and ClsNNCurrent will hold the same value while the mouse moves inside a control.
    ClsNNPrevious := ClsNNCurrent
    MouseGetPos, , , , ClsNNCurrent
    CtrlClassMouseCurrent := ClsNNCurrent
    
    ; When the mouse moved from one control to the other. ClsNNPrevious and ClsNNCurrent, both hold a different value.
    if (ClsNNPrevious != ClsNNCurrent)
        CtrlClassMousePreviouse := ClsNNPrevious

    
    if (msg = Wm_LbuttonDown) {
        ; When some control under the mouse is a Edit control and the script is not already getting a key.
        If (InStr(CtrlClassMouseCurrent, "Edit") && InputActive = 0) {
            GuiControlGet, IsControlOn, Enabled, %CtrlClassMouseCurrent%
            
            ; If this control is not disabled.
            If (IsControlOn = 1) {
                InputActive := 1
                
                ; store it's current text and give the control input focus (actually it's the other way around, hehe). 
                ControlFocus, %CtrlClassMouseCurrent%
                ControlGetText, ctrlTxt, %CtrlClassMouseCurrent%
                
                ; Briefly anable this control to call function EditGetKey when it recieves some input.
                GuiControl +gEditGetKey, %CtrlClassMouseCurrent%
                Send, ^a{bs}
                GuiControl -gEditGetKey, %CtrlClassMouseCurrent%
            }

        }
    }
}

; Writes back the name of any keyboard, mouse or joystic button to a edit control.
EditGetKey() {
    static InputKeys := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9","Numpad10","NumpadEnter", "NumpadAdd", "NumpadSub","NumpadMult", "NumpadDev", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "Left", "Right", "Up", "Down", "Home","End", "PgUp", "PgDn", "Del", "Ins", "Capslock", "Numlock", "PrintScreen", "Pause", "LControl", "RControl", "LAlt", "RAlt", "LShift","RShift", "LWin", "RWin", "AppsKey", "BackSpace", "space", "Tab", "Esc", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N","O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "/", "[", "]", "\", "'", ";", "` ","Joy1", "Joy2", "Joy3", "Joy4", "Joy5", "Joy6", "Joy7", "Joy8", "Joy9", "Joy10", "Joy11", "Joy12", "Joy13", "Joy14", "Joy15", "Joy16", "Joy17","Joy18", "Joy19", "Joy20", "Joy21", "Joy22", "Joy23", "Joy24", "Joy25", "Joy26", "Joy27", "Joy28", "Joy29", "Joy30","Joy31", "Joy32"]

    KeyWait("Lbutton")
    
    ; prevent right click from showing a context menu.
    Hotkey, IfWinExist, AutoWalk
    Hotkey, Rbutton Up, RbttnUp, On
    
    ; loop untill the user pressed some button and as long as the mouse is over some edit box.
    loop {
        ; Getting the key here, there stored in array Inputkeys.
        For k, ThisKey in InputKeys {
            if GetKeyState(ThisKey, "P") {
                GuiControl, , %CtrlClassMouseCurrent%, %ThisKey%
                Key := KeyWait(ThisKey)
                Break
            }
            
            If (!InStr(CtrlClassMouseCurrent, "Edit")) {
                GuiControl, , %CtrlClassMousePreviouse%, %ctrlTxt%
                Key := 1
                Break
            }
        }
        If (Key)  
            break
    }
    ControlFocus, &Start Game
    
    ; Write new values, if the for loop didn't break because the mouse moved outside the controll
    If (Key != 1)  
        IniWrite, %ThisKey%, %ConfigFile%, Settings, %A_GuiControl%
        
    GUI, submit, nohide
    
    RbttnUp:
        Hotkey, IfWinExist, AutoWalk
        Hotkey, Rbutton Up, RbttnUp, Off
        
    InputActive := 0
    return
}

; read variables from a ini file and create variables.
ReadIni(InputFile) {
    Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
    {
        if (((InStr(A_LoopField, "[")) = 1 ? 1) || ((InStr(A_LoopField, "`;")) = 1 ? 1) || !A_LoopField)
            Continue
            
        TmpVar := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %TmpVar% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
    }                                                              
}

; Turns the ingame camera to follow the player.
AutoTurnCamera(K, rL, rR) {
    WinGetActiveStats, Title, Width, Height, X, Y
    Rad := 180 / 3.1415926

    While(GetKeyState(K)) {
        MouseGetPos, xpos, ypos
        xpos := xpos - Width/2, ypos := Height/2 - ypos

        if ((xpos*xpos + ypos*ypos < 10000) || ((ypos > 0) && (Abs(ATan(xpos / ypos)) * Rad < 20)))
            continue

        if (xpos > 0) {
            Send {%rR% down}
            Sleep, 10
            Send {%rR% up}
        } else {
            Send {%rL% down}
            Sleep, 10
            Send {%rL% up}
        }
    }
}

; Return the first two bytes in a 32 bit integer. The first of the two bytes is the Most Significant byte (MSB)
HIWORD(Dword,Hex=0){
    BITS:=0x10,WORD:=0xFFFF
    return (!Hex)?((Dword>>BITS)&WORD):Format("{1:#x}",((Dword>>BITS)&WORD))
}

; Return the second two bytes in a 32bit Integer. The last of the two bytes is the Least Significant byte (LSB)
LOWORD(Dword,Hex=0){
    WORD:=0xFFFF
    Return (!Hex)?(Dword&WORD):Format("{1:#x}",(Dword&WORD))
}

;_______________________________________ Game Specific Hotkeys _______________________________________

#IfWinActive, ahk_group ClientGroup

UserHotKey:
    If (IsoCam = 1) {
        If (KeyWait("Lbutton", "T0.200", 1) = 0) {
            If (KeyWait("Lbutton", "D T0.200", 1) = 0) {
                keywait("Lbutton")
                KeyState := KeyState != "down" ? "down" : "up"
                Send, {Lbutton %KeyState%}

                If (TurnCamera = 1 && KeyState = "Down")
                    AutoTurnCamera("LButton", LeftKey, RightKey)

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
        Hotkey, W, InterruptDownState, OFF
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
