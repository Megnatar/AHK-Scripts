/*
    Autowalk v1.0.4.1 writen by Megnatar

    Everyone is free to use, add code and redistribute this script.
    But you MUST always credit ME Megnatar for creating the source!
    The source code for this script can be found on my Github repository:
     https://github.com/Megnatar/AHK-Scripts/blob/master/Autowalk.ahk

    Usage:
    To add a new game, just drop the executable on the gui or use the browse button.

    Click in a edit box to set a new hotkey. Any posible key will do. The script will write
    the name of the key to the edit control. For example pressing numpad1 after a click inside a edit
    control will write numpad1 to it, not 1. Game controllers are supported.

    Enable the checkbox "RPG Games" for games with a isometric camera (top Down view).
    All these games use left mouse button Down to move around. Thus, double click the left
    mouse button to send LButton Down. Click again, once or twice, to stop.
    The hotkey and the key to send, are both configurable.

    When the camera does not automatically follow the player enable "Turn camera" and
    specify the two keys used by the game to rotate the camera left or right.
    A double click will now also enable auto rotation of the camera.

    IMPORTANT:
    - If the game does not accept input. Then enable admin mode and try again!
    - Droping files will NOT work when the script is running in admin mode.
    - You have to use the real executable for you're game, not a shortcut that looks like a exe.
      This is usually the case with games build on the Unreal engine. Look for a folder named Binaries or Bin.

    Great thanx to Turul1989 for helping me debug and helping me undestand what needs to be added.
*/

#NoEnv
#Persistent
#SingleInstance force
#InstallKeybdHook
#KeyHistory 0
;ListLines off
SetBatchLines -1
SetTitleMatchMode 3
SetKeyDelay 5, 1
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On
sendmode Input

Global Wm_LbuttonDown   := 0x201
, Wm_Mousemove          := 0x200
, Wm_DraggGui           := 0x5050
, WM_NCLBUTTONDOWN      := 0xA1
, InputActive           := 0
, TipsOff               := 0
, ConfigFile            := "Settings.ini"
, hScriptGui
, ControlBelowMouse
, ControlOldBelowMouse
, ctrlTxt
, A_hotKey

OpenFolder_TT := "Open game installation dir.`nControl+Click to open script dir."
hKey_TT       := "HOTKEY.`nClick then press a button to change."
sKey_TT       := "SENDKEY.`nClick then press a button to change."
RunGame_TT    := "Start a new game session.`nActivates it, if it's already running."
LeftKey_TT    := "The key used by the game to turn camera left."
RightKey_TT   := "The key used by the game to turn camera right."
Browse_TT     := "Browse for a game to add."
LeftKey       := "Left"
RightKey      := "Right"
Gui_X         := "Center"
Gui_Y         := "Center"
KeyState      := "Up"
sKey          := "W"
hKey          := "XButton2"
RPGGames      := 0
TurnCamera    := 0
Admin         := 0
OnTop         := 1

If (FileExist(ConfigFile)) {
    ReadIni(ConfigFile)
}

if (Admin & !A_IsAdmin) {
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

GUI +LastFound +OwnDialogs +AlwaysOnTop +hWndhScriptGui -Theme
Gui Add, GroupBox, x8 y0 w362 h194 +Center, Drop you're game executable here
Gui Add, GroupBox, x16 y8 w345 h64
Gui Font, s10 Bold
Gui Add, Text, x24 y36 w329 h19 +Center +BackgroundTrans +0x200 vTitle, %Title%
Gui Font
Gui Add, Picture, x20 y18 w50 h50 +0x09 vPic, % "HICON:*" hIcon := LoadPicture(FullPath, "GDI+ Icon1 w50", ImageType)
Gui Add, Button, x307 y18 w50 h18 vBrowse, &Browse
Gui Add, Button, x16 y160 w80 h23 vRunGame, &Start Game
Gui Add, Button, x104 y160 w80 h23 vOpenFolder, Open Folder
Gui Add, Button, x280 y160 w80 h23 gGuiClose, Exit
Gui Add, GroupBox, x16 y72 w345 h83
Gui Add, Text, x24 y80 w99 h14, Autowalk keys
Gui Add, Edit, x24 y100 w63 h21 Limit1 -TabStop vhKey, %hKey%
Gui Add, Edit, x24 y126 w63 h21 Limit1 -TabStop vskey, %skey%
Gui Add, CheckBox, x120 y80 w90 h23 Checked%Admin% vAdmin gAdmin, Runas Admin
Gui Add, CheckBox, x120 y104 w82 h23 Checked%RPGGames% vRPGGames gRPGGames, RPG Games
Gui Add, CheckBox, x120 y128 w82 h23 +Disabled Checked%TurnCamera% vTurnCamera gTurnCamera, Turn Camera
Gui Add, Edit, x212 y128 w60 h21 +Disabled Limit1 -TabStop vLeftKey, %LeftKey%
Gui Add, Edit, x280 y128 w60 h21 +Disabled Limit1 -TabStop vRightKey, %RightKey%
Gui Add, CheckBox, x216 y80 w104 h23 Checked%TipsOff% gTipsOff vTipsOff, Disable tooltips
Gui Add, CheckBox, x216 y100 w112 h23 Checked%OnTop% gOnTop vOnTop, Gui always on top

if (RPGGames = 1) {
    GuiControl([["Enable", "TurnCamera"]])
    if (TurnCamera = 1) {
        GuiControl([["Enable", "LeftKey"], ["Enable", "RightKey"]])
    }
}

Gui Show, w378 h201 x%Gui_X% y%Gui_Y%, AutoWalk

OnMessage(Wm_MouseMove, "WM_Mouse"), OnMessage(Wm_LbuttonDown, "WM_Mouse"), OnMessage(Wm_DraggGui, "WM_Mouse"), OnExit("ExitScript")
Return

;_______________________________________ Game Specific Code _______________________________________

#IfWinExist, AutoWalk
{
    #IfWinNotActive, AutoWalk
    {
        #IfWinExist, ahk_group ClientGroup
        {
            #IfWinActive, ahk_group ClientGroup
            {
                ; When this file "UserCode.ahk" resides in the same folder as where the script is.
                ; Then the code in that file is used by this script when the game window is active.
                ; Read comment on function ButtonSingleDouble() for more instructions.
                ;
                #Include *i UserCode.ahk

                HotKeyAutoWalk:
                If (RPGGames) {
                    If (A_Hotkey := KeyWait()) {
                        If (ErrLvL := KeyWait(A_hotKey, "D T0.2", 1) = 0) {
                            keywait(A_hotKey), KeyState := KeyState != "Down" ? "Down" : "Up"
                            Send {%A_hotKey% %KeyState%}

                            If ((TurnCamera = 1) & (KeyState = "Down")) {
                                AutoTurnCamera(A_hotKey, LeftKey, RightKey, VirtualKey := 1)
                            }
                        } else {
                            if (KeyState = "Down") {
                                KeyState := "Up"
                                Send {%A_hotKey% %KeyState%}
                            }
                        }
                    }
                } Else If (!RPGGames) {
                    InterruptDownState:

                    if (KeyState = "Down")
                        KeyWait()

                    KeyState := KeyState != "Down" ? "Down" : "Up"
                    Send {%sKey% %KeyState%}

                    if (KeyState = "Down") {
                        Hotkey, ~*Vk057, InterruptDownState, ON     ; Vk057 = w
                        Hotkey, ~*Vk01, InterruptDownState, ON      ; Vk01  = LButton
                    } else if (KeyState = "Up") {
                        Hotkey, ~*Vk057, InterruptDownState, OFF
                        Hotkey, ~*Vk01, InterruptDownState, OFF
                    }
                }
                Return
            }
        }
    }
}
Return

;_______________________________________ Script Lables _______________________________________
; Appart from the start game button. The only thing these lables do is save or change some
; gui related setting where needed.

GuiDropFiles:
    Loop, parse, A_GuiEvent, `n, `r
        FullPath := A_LoopField, Path := SubStr(A_LoopField, 1, InStr(A_LoopField, "\", ,-1)-1), ExeFile := SubStr(A_LoopField, InStr(A_LoopField, "\", ,-1)+1)

    FileGetSize,fileSize, %FullPath%, K
    if (FileSize < 1024)
        MsgBox,,FileSize: %FileSize% KB, % "The size of you're file is less then 1MB`n`nAre you sure this is the real exe and not a shortcut`nto a ecxecutable some folders below`n`nFile size: " FileSize "KB"

    If (FileExist(ConfigFile))
        FileDelete %ConfigFile%

    IniWrite %FullPath%, %ConfigFile%, Settings, FullPath
    IniWrite %Path%, %ConfigFile%, Settings, Path
    IniWrite %ExeFile%, %ConfigFile%, Settings, ExeFile
    IniWrite % Title := "Ready to start you're game", %ConfigFile%, Settings, Title
    IniWrite, % Admin := 1, %ConfigFile%, Settings, Admin
    Reload
Return

ButtonBrowse:
    FileSelectFile, FullPath, M3, , ,*.exe
    Loop, parse, % FullPath, `n, `r
        A_Index <= 1 ? Path := A_LoopField : ExeFile := A_LoopField
    if (ErrorLevel)
        Exit

    FileGetSize, fileSize, %FullPath%, K
    if ((FileSize < 1024) & (FileSize != ""))
        MsgBox,,FileSize: %FileSize% KB, % "The size of you're file is less then 1MB`n`nAre you sure this is the real exe and not a shortcut`nto a ecxecutable some folders below`n`nFile size: " FileSize "KB"

    If (FileExist(ConfigFile))
        FileDelete %ConfigFile%
        
    IniWrite, % Admin := 1, %ConfigFile%, Settings, Admin
    IniWrite % FullPath := Trim(Path) "\" Trim(ExeFile), %ConfigFile%, Settings, FullPath
    IniWrite %Path%, %ConfigFile%, Settings, Path
    IniWrite %ExeFile%, %ConfigFile%, Settings, ExeFile
    IniWrite % Title := "Ready to start you're game", %ConfigFile%, Settings, Title
    Reload
Return

Admin:
    GUI, submit, nohide
    if (Admin) {
        IniWrite, %Admin%, %ConfigFile%, Settings, Admin
        Reload
    } else {
        IniDelete, %ConfigFile%, Settings, Admin
        ExitApp
    }
Return

RPGGames:
    GUI, submit, nohide
    IniWrite, %RPGGames%, %ConfigFile%, Settings, RPGGames
    if (RPGGames) {
        ;sKey := hKey := "LButton"
        GuiControl([[ , "hKey", "LButton"], [ , "sKey", "LButton"], ["Enable", "TurnCamera"]])
        IniWrite, % hKey := "LButton", %ConfigFile%, Settings, hKey
        IniWrite, % sKey := "LButton", %ConfigFile%, Settings, sKey
    } else {
        ;TurnCamera := ""
        GuiControl([["enable", "hKey"], ["Disable", "TurnCamera"], ["Disable", "LeftKey"], ["Disable", "RightKey"], [ , "TurnCamera", "0"]])
        IniWrite, % TurnCamera := "", %ConfigFile%, Settings, TurnCamera
    }
    GUI, submit, nohide
Return

TurnCamera:
    GUI, submit, nohide
    IniWrite, %TurnCamera%, %ConfigFile%, Settings, TurnCamera
    if (TurnCamera) {
        GuiControl([["Enable", "LeftKey"], ["Enable", "RightKey"]])
    } else {
        GuiControl([["Disable", "LeftKey"], ["Disable", "RightKey"]])
    }
    GUI, submit, nohide
Return

TipsOff:
    GUI, submit, nohide
    if (TipsOff) {
        IniWrite, %TipsOff%, %ConfigFile%, Settings, TipsOff
    } else {
        IniDelete, %ConfigFile%, Settings, TipsOff
    }
Return

OnTop:
    GUI, submit, nohide
    tgl := OnTop < 1 ? "-" : "+"
    Gui 1:%tgl%AlwaysOnTop
    IniWrite, %OnTop%, %ConfigFile%, Settings, OnTop
Return

ButtonStartGame:
    ; Is the game already running?
    If (!(HwndClient := WinExist("ahk_exe " ExeFile))) {
        Run %ExeFile%, %Path%
        sleep, 10

        ; Keep on checking for our window to appear. This is untill var HwndClient holds some value.
        While(!(HwndClient := WinExist("ahk_exe " ExeFile))) {
            if (CheckWinExist < 30) {
                CheckWinExist += 1
                
                ; Show a counter in the GUI when the script is waiting longer then 4 seconds.
                if (CheckWinExist > 4)
                    GuiControl([[ , "Title", Title " " CheckWinExist ]])
                    
                    
            ; After 30 second a timeout will occur.
            } else if ((!HwndClient) & (CheckWinExist > 29)) {
                MsgBox,0x24, Something is not oke!?, % "Unable to find client GUI!`nDo you wish to wait a nother 30 seconds?"
                IfMsgBox Yes, {
                    CheckWinExist := ""
                    Continue
                } else {
                    HwndClient := "", CheckWinExist := "NotFound"
                    break
                }
            }
            sleep, 1000
        }
        ; Whem a timeout occurred and while() broke. Then jump back to the last return because messagebox choise was No.
        if (CheckWinExist = "NotFound") {
            Return
        } else {
            ; Remove timer from gui only when it started.
            if (CheckWinExist > 4)
                GuiControl([[ , "Title", Title]])
                
            WinSet, Bottom,, AutoWalk
            WinSet, Top,, ahk_id %hWndClient%
            
            ; Is active window the game window? A top most window is not always the active one.
            If (WinActive("A") != HwndClient)
                WinActivate, ahk_id %hWndClient%, , AutoWalk
        }
    ; When the game was already running.    
    } else if (HwndClient) {
        WinGet, WinState, MinMax, ahk_exe %ExeFile%, , AutoWalk

        if (WinState = -1) {
            WinRestore, ahk_id %hWndClient%,, AutoWalk
        } else {
            WinActivate, ahk_id %hWndClient%,, AutoWalk
        }
    }
    sleep 5000
    
    ; Some games launch a different window first.
    ; A window must exist by now. But is it our window? A game GUI never contains any
    ; controls in it. So getting all controls of the window that was just launched.
    WinGet, EmptyCtrlList, ControlList, ahk_exe %ExeFile%
    
    ; Eveluates true when var EmptyCtrlList is indeed empty.
    ; And if the game was not already launched by the script.
    If ((EmptyCtrlList ? 0 : 1) & (!ClientGroup)) {
    
        ; Get the window title and it's class name when a new game is launched for the first time.
        ; Save class and title to setting.ini file and put the title on the gui.
        If ((InStr(Title, "Ready to start you're game")) | (!Title)) {
            WinGetTitle, Title, ahk_exe %ExeFile%
            WinGetClass, ClientGuiClass, ahk_exe %ExeFile%
            
            IniWrite %Title%, %ConfigFile%, Settings, Title
            IniWrite %ClientGuiClass%, %ConfigFile%, Settings, ClientGuiClass
            
            GuiControl([[ , "Title", Title], ["MoveDraw", "Pic"]])
        }        
    } else if (!ClientGroup & !OddCLient) {
        MsgBox,0x24, Game Window!?, % "This does not look like a game window!`n`nDo you want to reload the script?`nYou should then press the Start Game`nbutton once the game window is active."
        IfMsgBox Yes, {
            Reload
        } else If (!OddCLient) {
            If ((InStr(Title, "Ready to start you're game")) | (!Title)) {
                WinGetTitle, Title, ahk_exe %ExeFile%
                WinGetClass, ClientGuiClass, ahk_exe %ExeFile%
                
                IniWrite %Title%, %ConfigFile%, Settings, Title
                IniWrite %ClientGuiClass%, %ConfigFile%, Settings, ClientGuiClass
                IniWrite % OddCLient := 1, %ConfigFile%, Settings, OddCLient
                
                GuiControl([[ , "Title", Title], ["MoveDraw", "Pic"]])
            }
        }
    }
    
    ; Create ClientGroup only once. The "ahk_group ClientGroup" is used by #IfWin[Not]Exist
    ; and #IfWin[Not]Active. All directives are loaded before ahk runs a script. Thus they
    ; don't understand variables. However ahk_group is supported.
    if (!ClientGroup, ClientGroup := 1)
        GroupAdd, ClientGroup, ahk_class %ClientGuiClass%

    Hotkey, ~%hKey%, HotKeyAutoWalk, On
Return

ButtonOpenFolder:
    KeyWait("LButton")
    If ((GetKeyState("LControl", "P")) | (GetKeyState("RControl", "P"))) {
        Run, Explorer.exe "%A_ScriptDir%"
    } else {
        Run, Explorer.exe "%Path%"
    }
Return

GuiEscape:
GuiClose:
    ExitApp

;_______________________________________ Script Functions _______________________________________

; Read ini file and create variables. Sections are not supported!
; Referenced variables are not local to functions. So %VarRef% represents global
; variables to which some value is added %VarRef% := "ValueOfVar"
;
ReadIni(InputFile, LoadSection = 0) {
    Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
    {
        if (LoadSection) {
            if (InStr(A_Loopfield, "[")) {
                SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
                Continue
            }
            If (LoadSection = SectionName) {
                VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)        
            }
        }
        
        if (((InStr(A_LoopField, "[")) = 1 ? 1) || ((InStr(A_LoopField, "`;")) = 1 ? 1) || !A_LoopField)
                Continue
            VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
    }
    Return
}

; KeyWait as a function for more flexible usage. Returns the key it waited for or ErrorLevel.
; When no parameters are used, keywait will use the value in A_ThisHotkey as the key to wait for.
;
KeyWait(Key = 0, Options = 0, ErrLvL = 0) {
    keywait, % ThisKey := Key ? Key : RegExReplace(A_ThisHotkey, "[~\*\$]"), % Options
    Return ErrLvL = 1 ? ErrorLevel : ThisKey
}

; Returns the last hotkey used with all basic modifiers removed from it.
ThisHotKey() {
    Return RegExReplace(A_ThisHotkey, "[~\*\$]")
}

; GuiControl as a function for more flexible usage. Parameter ControlID can be a array.
; For example, if you want to use the GuiControl command 3 times in a row.
; Then the array should look something like:
;  ControlID := [[SubCommand, ControlID, Value], [SubCommand, ControlID], [ , ControlID, Value]]
;
; You can also insert objects directly on the parameter for ControlID.
;  GuiControl([[SubCommand, ControlID, Value], [SubCommand, ControlID], [ , ControlID, Value]])
;
GuiControl(ControlID, SubCommand = 0, Value = 0) {
    If (IsObject(ControlID)) {
        Loop % ControlID.Length() {
            GuiControl % ControlID[A_index][1], % ControlID[A_index][2], % ControlID[A_index][3]
        }
    } else {
        GuiControl % SubCommand, % ControlID, % Value
    }
    Return ErrorLevel
}

; A combination of Control and ControlGet. By default the ControlGet command will be used. To use Control set parameter NotGet to one.
; Parameter Parms should be a Array of Objects. Each seperate Object will hold the command options. Only one of the commands can be
; used for each call done to the function.
;
; The order of the options for the commands should be the same in the array as used by the command.
; E.g.
;  ControlGet_Parms := [[OutputVar, Cmd, Value, Control, WinTitle, WinText, ExcludeTitle, ExcludeText], [OutputVar, Cmd, Value ... etc]]
;  Control_Parms    := [[Cmd, Value, Control, WinTitle, WinText, ExcludeTitle, ExcludeText], [Cmd, Value ... etc]]
;
;  ControlGetControl(ControlGet_Parms)
;  ControlGetControl(Control_Parms, 1)
;  ControlGetControl([[Cmd, Value, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]], 1)
;
ControlGetControl(Parms, NotGet = 0) {
    If (IsObject(Parms)) {
        if (!NotGet) {
           Loop % Parms.Length() {
                OutputVar := Parms[A_index][1]
                ControlGet %OutputVar%, % Parms[A_index][2], % Parms[A_index][3], % Parms[A_index][4], % Parms[A_index][5], % Parms[A_index][6], % Parms[A_index][7], % Parms[A_index][8]
            }
       } else if (NotGet) {
            Loop % Parms.Length() {
                Control % Parms[A_index][1], % Parms[A_index][2], % Parms[A_index][3], % Parms[A_index][4], % Parms[A_index][5], % Parms[A_index][6], % Parms[A_index][7]
            }
        }
    }
    Return ErrorLevel
}

; Keep track of mouse movement and left mouse button state inside the GUI.
WM_Mouse(wParam, lParam, msg, hWnd) {
    Static ClsNNPrevious, ClsNNCurrent, _TT, CurrControl, PrevControl
    ListLines off   ; Even when globaly enabled. Best to set it off here.

    ; ClsNNPrevious and ClsNNCurrent will hold the same value while the mouse moves inside a control.
    ClsNNPrevious := ClsNNCurrent
    MouseGetPos, , , , ClsNNCurrent
    ControlBelowMouse := ClsNNCurrent

    ; When the mouse moved from one control to the other. ClsNNPrevious and ClsNNCurrent, both hold a different value.
    if (ClsNNPrevious != ClsNNCurrent)
        ControlOldBelowMouse := ClsNNPrevious

    if ((msg = WM_MOUSEMOVE) & (!TipsOff)) {
        CurrControl := A_GuiControl

        if ((ClsNNPrevious != ClsNNCurrent) & (!InStr(CurrControl, " "))) {
            ToolTip  ; Turn off any previous tooltip.
            SetTimer, DisplayToolTip, 750
            PrevControl := CurrControl
        }
        return

        DisplayToolTip:
        SetTimer, DisplayToolTip, Off
        ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
        SetTimer, RemoveToolTip, 5000
        return

        RemoveToolTip:
        SetTimer, RemoveToolTip, Off
        ToolTip
        return
    }

    if (msg = Wm_LbuttonDown) {
        SetTimer, RemoveToolTip, Off
        ToolTip

        ; When some control under the mouse is a Edit control and the script is not already getting a key.
        If ((InputActive = 0) & (InputActive := InStr(ControlBelowMouse, "Edit"))) {
            GuiControlGet, IsControlOn, Enabled, %ControlBelowMouse%

            ; Ignore the windows used by autohotkey for ListVars, ListLines and so on.
            If (WinGetActiveTitle() != "AutoWalk")
             Return

            ; And when this control is not disabled.
            If (IsControlOn = 1) {

                ; store it's text and give the control input focus (actually it's the other way around, hehe).
                ControlFocus, %ControlBelowMouse%
                ControlGetText, ctrlTxt, %ControlBelowMouse%

                ; Briefly enable this control to call function EditGetKey when it recieves some input.
                GuiControl([["+gEditGetKey", ControlBelowMouse], [ , ControlBelowMouse], ["-gEditGetKey", ControlBelowMouse]])
            } else {
                InputActive := 0
            }
        }
        if ((GetKeyState("LButton", "P")) & (!A_GuiControl)) {
            PostMessage, Wm_DraggGui
        }
        Return
    }

    if (msg = Wm_DraggGui) {
        if ((GetKeyState("LButton", "P")) & (!A_GuiControl)) {
            FadeInOut(hScriptGui, 1)
            PostMessage, WM_NCLBUTTONDOWN, 2
            KeyWait("LButton")
            FadeInOut(hScriptGui)
        }
        Return
    }
}

WinGetActiveTitle() {
    WinGetActiveTitle OutputVar
    Return OutputVar
}

; Write back the name of any keyboard, mouse or joystick button to a edit control.
EditGetKey() {
    static InputKeys := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9","Numpad10","NumpadEnter", "NumpadAdd", "NumpadSub","NumpadMult", "NumpadDev", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "Left", "Right", "Up", "Down", "Home","End", "PgUp", "PgDn", "Del", "Ins", "Capslock", "Numlock", "PrintScreen", "Pause", "LControl", "RControl", "LAlt", "RAlt", "LShift","RShift", "LWin", "RWin", "AppsKey", "BackSpace", "space", "Tab", "Esc", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N","O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "/", "[", "]", "\", "'", ";", "` ","Joy1", "Joy2", "Joy3", "Joy4", "Joy5", "Joy6", "Joy7", "Joy8", "Joy9", "Joy10", "Joy11", "Joy12", "Joy13", "Joy14", "Joy15", "Joy16", "Joy17","Joy18", "Joy19", "Joy20", "Joy21", "Joy22", "Joy23", "Joy24", "Joy25", "Joy26", "Joy27", "Joy28", "Joy29", "Joy30","Joy31", "Joy32"]

    KeyWait("LButton")

    ; Prevent a right click from showing the context menu.
    Hotkey, IfWinExist, AutoWalk
    Hotkey, Vk02 Up, RbttnUp, On     ; Vk02 = RButton

    ; Loop untill the user pressed some button or as long as the mouse is over some edit box.
    Critical
    loop {
        ; Getting user input from array Inputkeys.
        For k, ThisKey in InputKeys {
            if (GetKeyState(ThisKey, "P")) {
                GuiControl(ControlBelowMouse, "", ThisKey)
                ExitLoop := KeyWait(ThisKey)
                Break
            }
            ; When ControlBelowMouse does not contain the word "Edit". Then the mouse moved away from the control.
            If (!InStr(ControlBelowMouse, "Edit")) {
                ExitLoop := 1
                GuiControl(ControlOldBelowMouse, "", ctrlTxt)
                ControlFocus, %ControlBelowMouse%
                Break
            }
        }
        If (ExitLoop)
            break
    }
    Critical Off
    ControlFocus, Button2
    GUI, submit, nohide

    ; Save new values to Settings.ini if the For loop didn't break when the mouse moved outside the control.
    If (ExitLoop != 1)
        IniWrite, %ThisKey%, %ConfigFile%, Settings, %A_GuiControl%

    RbttnUp:
        Hotkey, IfWinExist, AutoWalk
        Hotkey, Vk02 Up, RbttnUp, Off

    InputActive := 0
    Return
}

; Send some key on a sinlge or double press of a button.
; The hotkey is optional and when ThisHotKey is empty Keywait() will return the last hokey used.
; This function can be used with the UserCode.ahk file e.g.:
; Below code would send A when F is pressed once. And B when F is pressed twice
; F::
;   ButtonSingleDouble("A", "B")
; Return
;
; And this will send B when you double click the right mouse button
; ~RButton::
;   ButtonSingleDouble("", "B")
; Return
;
ButtonSingleDouble(KeySingle, KeyDouble, ThisHotKey = 0, WaitRelease = 0) {
    if (WaitRelease) {
        Send {%KeySingle% Down}
        A_hotKey := ThisHotKey ? keywait(ThisHotKey) : keywait()
        Send {%KeySingle% Up}

        if (keywait(A_hotKey, "D T0.1", 1) = 0) {
            Send {%KeyDouble% Down}
            KeyWait(A_hotKey)
            Send {%KeyDouble% Up}
        }
    } else if (!WaitRelease) {
        A_hotKey := ThisHotKey ? keywait(ThisHotKey) : keywait()

        if (keywait(A_hotKey, "D T0.1", 1) = 0) {
            Send {%KeyDouble% Down}{%KeyDouble% Up}
        } else {
            Send {%KeySingle% Down}{%KeySingle% Up}
        }
    }
    Return
}

; Automaticly turn the ingame camera to follow the player when some key is down.
AutoTurnCamera(KeyDown, RotateL, RotateR, VirtualKey = 0, DownPeriod = 40, DeadZone = 35) {
    Static Rad := 180 / 3.1415926

    ; The width and hight of the client gui might change in between calls, so getting them here.
    WinGetPos, , ,gW, gH, A

    ; Check mouse position and turns the camera when the mouse moved outside a deadszone while the key in KeyDown has status Down.
    ; By default the physical key state is monitored. Set parameter VirtualKey to 1 to check the logical key state. Logical is when
    ; a key is send Down by the send command or in some other way.
    ;
    While(GetKeyState(KeyDown, (!VirtualKey ? "P" : ""))) {
        MouseGetPos, mX, mY

        ; Calculate cursor position, where the vertical/horizontal centre of the display are seen as zero. Both the left and right side
        ; of the display are seen as positive (Abs). A triangle (ATan) of 70 degrees (35*2) is created from the very centre to the top/bottom.
        ; These triangles will be the dead zone, where the camera does not turn.
        ;
        if (((((X := mX - gW/2) * mX) + ((Y := gH/2 - mY) * mY) < 10000) | (Y > 0)) & ((Abs(ATan(X/Y)) * Rad) < DeadZone)) {
            continue
        }

        ; Turn the ingame camera left or right when the mouse moved outside the deadzone.
        ; I advice to make the value in DownPeriod not greater then the 50ms sleep. If you do,
        ; then also increase the sleep period to somthing greater then the down perdiod.
        ; This will result in a smoother turning of the camera.
        ;
        if (X < 0) {
            Send {%RotateL% Down}
            Sleep, %DownPeriod%
            Send {%RotateL% Up}
        } else {
            Send {%RotateR% Down}
            Sleep, %DownPeriod%
            Send {%RotateR% Up}
        }
        sleep 50
    }
    Return
}

; Fade transparency out or in while dragging the Gui.
FadeInOut(hWnd, dragg = 0) {
    static Transparency := 250
    if (dragg = 1) {
        Loop {
            If (A_TickCount >= WaitNextTick) {
                WaitNextTick := A_TickCount+50
                WinSet, Transparent, % Transparency -= 20, ahk_id %hWnd%
                If (Transparency <= 210)
                    break
            }
        }
    } else if (dragg = 0) {
        Loop {
            If (A_TickCount >= WaitNextTick) {
                WaitNextTick := A_TickCount+50
                WinSet, Transparent, % Transparency += 20, ahk_id %hWnd%
                If (Transparency >= 255) {
                    WinSet, Transparent, Off, ahk_id %hWnd%
                    break
                }
            }

        }
    }
    return
}

; This is called right before the script terminates. It keep the setting.ini clean
; from unused values and saves GUI position.
ExitScript() {
    WinGetPos, Gui_X, Gui_Y, ,, AutoWalk

    ; See if there are any variables in the ini that are empty.
    Loop, parse, % FileOpen(ConfigFile, 0).read(), `n, `r
    {
        ; Create section name variable 'SectionName'.
        if (InStr(A_Loopfield, "[")) {
            SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
            Continue
        }
        ; Purge empty variables from the configuration file.
        If (((SubStr(A_LoopField, InStr(A_LoopField, "=")+1)) <= "               "))
            IniDelete, %ConfigFile%, %SectionName%, % SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1)
    }
    ; Remember the position of the script GUI.
    if ((Gui_X > -1) & (Gui_Y > -1)) {
        IniWrite, %Gui_X%, %ConfigFile%, Settings, Gui_X
        IniWrite, %Gui_Y%, %ConfigFile%, Settings, Gui_Y
    }
}