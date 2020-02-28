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

    Enable the checkbox "RPG Games" for games with a isometric camera (Top down view).
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
ListLines off
SetBatchLines -1
SetTitleMatchMode 3
SetKeyDelay 5, 1
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On
sendmode Input

Global Wm_LbuttonDown:=0x201
, Wm_Mousemove :=0x200
, InputActive := 0
, focused_control
, CtrlClassMousePreviouse
, CtrlClassMouseCurrent
, ctrlTxt
, ConfigFile

ConfigFile  := "Settings.ini"
LeftKey     := "Left"
RightKey    := "Right"
IsoCam      := 0
Admin       := 0
TurnCamera  := 0


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

Gui Add, GroupBox, x8 y0 w362 h194
Gui Add, GroupBox, x16 y8 w345 h64 +Center, Drop you're game executable here.
Gui Font, s10 Bold
Gui Add, Text, x24 y32 w329 h23 +Center +0x200 vTitle, %Title%
Gui Font
Gui Add, Picture, x24 y16 w50 h50 0x6 0x0003 +AltSubmit +BackgroundTrans vPic, %FullPath%
Gui Add, Button, x16 y160 w80 h23 vRunGame gRunGame, &Start Game
Gui Add, Button, x104 y160 w80 h23 gOpenFolder, Open folder
Gui Add, Button, x280 y160 w80 h23 gGuiClose, Exit
Gui Add, GroupBox, x16 y72 w345 h83
Gui Add, Text, x24 y88 w44 h23, Hotkey:
Gui Add, Edit, x64 y88 w63 h21 Limit1 vHkey, %Hkey%
Gui Add, CheckBox, x136 y88 w80 h23 Checked%IsoCam% vIsoCam gIsoCam, RPG Games
Gui Add, CheckBox, x136 y120 w79 h17 +Disabled Checked%TurnCamera% vTurnCamera gTurnCamera, TurnCamera
Gui Add, CheckBox, x224 y88 w83 h23 Checked%Admin% vAdmin gAdmin, Run as admin
Gui Add, Edit, x224 y120 w60 h21 +Disabled Limit1 T1 vLeftKey, %LeftKey%
Gui Add, Edit, x288 y120 w60 h21 +Disabled Limit1 T1 vRightKey, %RightKey%
Gui Show, w378 h201, AutoWalk


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

; Send some key on a singe or double press
ButtonDoubleSingle(KeySingle, KeyDouble, A_hotKey := "") {
    A_hotKey := A_hotKey ? keywait(A_hotKey) : keywait()

    if (keywait(A_hotKey, "D T0.2", 1) = 0) {
        Send, %KeyDouble%
    } else {
        send, %KeySingle%
    }
}

; KeyWait as a function for more flexible usage.
KeyWait(K := "", O := "", ErrLvL := "") {
    keywait, % Key := K ? K : RegExReplace(A_ThisHotkey, "[~\*\$]"), % O
    Return ErrLvL = 1 ? ErrorLevel : Key
}

; Keep track of mouse movement and left click inside the gui.
WM_Mouse(wParam, lParam, msg, hWnd) {
    Static ClsNNPrevious, ClsNNCurrent, X, Y
    Listlines off
    ;X := HIWORD(LPARAM), Y := LOWORD(LPARAM)
    
    GuiControlGet, focused_control, Focus
    ; ClsNNPrevious and ClsNNCurrent will hold the same value while the mouse moves inside a control.
    ClsNNPrevious := ClsNNCurrent
    MouseGetPos, , , , ClsNNCurrent
    CtrlClassMouseCurrent := ClsNNCurrent

    ; When the mouse moved from one control to the other. ClsNNPrevious and ClsNNCurrent, both hold a different value.
    if (ClsNNPrevious != ClsNNCurrent)
        CtrlClassMousePreviouse := ClsNNPrevious

    if (msg = Wm_LbuttonDown) {
        ; When some control under the mouse is a Edit control and the script is not already getting a key.
        If ((InputActive = 0) & (InputActive := InStr(CtrlClassMouseCurrent, "Edit"))) {
            GuiControlGet, IsControlOn, Enabled, %CtrlClassMouseCurrent%

            ; When this control is not disabled.
            If (IsControlOn = 1) {
                ; store it's current text and give the control input focus (actually it's the other way around, hehe).
                ControlFocus, %CtrlClassMouseCurrent%
                ControlGetText, ctrlTxt, %CtrlClassMouseCurrent%

                ; Briefly anable this control to call function EditGetKey when it recieves some input.
                GuiControl +gEditGetKey, %CtrlClassMouseCurrent%
                GuiControl, , %CtrlClassMouseCurrent%, 
                GuiControl -gEditGetKey, %CtrlClassMouseCurrent%
            } else {
                InputActive := 0
            }
        }
    }
}


; Writes back the name of any keyboard, mouse or joystick button to a edit control.
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
            ; When CtrlClassMouseCurrent does not contain the word "Edit". Then the mouse moved away from the control.
            If (!InStr(CtrlClassMouseCurrent, "Edit")) {
                GuiControl, , %CtrlClassMousePreviouse%, %ctrlTxt%
                ControlFocus, %CtrlClassMouseCurrent%
                Key := 1
                Break
            }
        }
        If (Key)
            break
    }
    ;GUI, submit, nohide
    
    ControlFocus, Button1
    send {tab}
    ;GuiControl, Focus, &Start Game
    ; Write new values, if the for loop didn't break because the mouse moved outside the control.
    If (Key != 1)
        IniWrite, %ThisKey%, %ConfigFile%, Settings, %A_GuiControl%



    RbttnUp:
        Hotkey, IfWinExist, AutoWalk
        Hotkey, Rbutton Up, RbttnUp, Off

    InputActive := 0, CtrlClassMousePreviouse := ""
    exit
}

; Read ini file and create variables. Referenced variables are not local to functions.
ReadIni(InputFile) {
    Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
    {
        if (((InStr(A_LoopField, "[")) = 1 ? 1) || ((InStr(A_LoopField, "`;")) = 1 ? 1) || !A_LoopField)
            Continue

        TmpVar := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %TmpVar% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
    }
}

; Turn the ingame camera to follow the player.
AutoTurnCamera(Key, RotateL, RotateR, KeyPressDuration = 50, DeadZone = 45) {
    Static Rad := 180 / 3.1415926
    SendMode, Input
    
    WinGetPos, , ,gW, gH, A

    ; Loop while the key is in a logical downstate. For physical status use While(GetKeyState(Key, "P"))
    While(GetKeyState(Key)) {

        MouseGetPos, mX, mY
        mX := mX - gW/2, mY := gH/2 - mY

        ; Do nothing when the mouse is inside a degree triangulated dead zone.
        ; The dead zone starts at the center of the screen and ends at the top, 30 dagrees on each side.
        if ((((mX*mX+mY*mY < 5000) || (mY > 0)) & (Abs(ATan(mX/mY)) * Rad < DeadZone)))
            continue

        ; Turn right when the x position of the mouse is positive and left when negative.
        if (mX > 0) {
            Send {%RotateR% down}
            Sleep, %KeyPressDuration%
            Send {%RotateR% up}
        } else {
            Send {%RotateL% down}
            Sleep, %KeyPressDuration%
            Send {%RotateL% up}
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
{
    #Include *i UserCode.ahk

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

        State := ToggleKey(RegExReplace(A_ThisHotkey, "[~\*\$]"), "w")

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
}
