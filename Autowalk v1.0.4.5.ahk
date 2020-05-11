/*
    Autowalk v1.0.4.1 writen by Megnatar ⬖⬘⬗⬙

    Everyone is free to use, add code and redistribute this script.
    But you MUST always credit ME Megnatar for creating the source!
    The source code for this script can be found on my Github repository:
     https://github.com/Megnatar/AHK-Scripts/blob/master/Autowalk.ahk

    Great thanx to Turul1989 for helping me debug and undestand what needs to be added.
*/

#NoEnv
#SingleInstance force
#InstallKeybdHook
#KeyHistory 0
ListLines off
SetBatchLines -1
SetTitleMatchMode 3
SetKeyDelay 5, 1
SetWorkingDir %A_ScriptDir%
sendmode Input
CoordMode, Mouse, screen

Global Wm_LbuttonDown   := 0x201
, Wm_Mousemove          := 0x200
, Wm_DraggGui           := 0x5050
, WM_NCLBUTTONDOWN      := 0xA1
, Ws_Caption            := 0xC00000
, Ws_Border             := 0x800000
, InputActive           := 0
, TipsOff               := 0
, ConfigFile            := A_ScriptDir "\Settings.ini"
, Profiles              := A_ScriptDir "\GameProfiles\GamesConfig.ini"
, UserCodeFiles         := A_ScriptDir "\GameProfiles\UserCode Files"
, IconLib               := []
, hScriptGui
, hClipMsg
, ControlBelowMouse
, ControlOldBelowMouse
, ctrlTxt
, A_hotKey
, now_x
, now_y
, Title

RPGGames                := 0
TurnCamera              := 0
Admin                   := 0
ShowGameList            := 0
OnTop                   := 0
i                       := 0
FS                      := 8
Xm	                    := Round(FS*1.25)
Ym 	                    := Round(FS*0.75)
FullScreen              := 0xb4000000
AppwindowAlwaysOnTop    := 0x20040808
WS_EX_TOPMOST           := 0x00000008
MenuItems               := {"Toggle Admin": "Admin", "Toggle Tooltips off": "TipsOff", "Toggle OnTop": "OnTop", "Show Game List": "ShowGameList"}
DropNotice              := "Drop you're game executable here"
OpenFolder_TT           := "Open game installation dir.`nControl+Click to open script dir."
hKey_TT                 := "HOTKEY.`nClick then press a button to change."
sKey_TT                 := "SENDKEY.`nClick then press a button to change."
RunGame_TT              := "Start a new game session.`nActivates it, if it's already running."
LeftKey_TT              := "The key used by the game to turn camera left."
RightKey_TT             := "The key used by the game to turn camera right."
Browse_TT               := "Browse for a game to add."
LeftKey                 := "Left"
RightKey                := "Right"
Gui_X                   := "Center"
Gui_Y                   := "Center"
KeyState                := "Up"
sKey                    := "W"
hKey                    := "XButton2"

If (FileExist(ConfigFile)) {
    iniRead(ConfigFile)
}

if ((Admin = 1) & !A_IsAdmin) {
    #SingleInstance force
    Try {
        If (A_IsCompiled) {
            Run *RunAs "%A_ScriptFullPath%"
        } Else {
            Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
        }
    } Catch ThisError {
        MsgBox % ThisError
    }
    ExitApp
}

GUI % "+LastFound " (!Title ? ("+", OnTop := 1) : (OnTop ? "+" : "-")) "AlwaysOnTop +OwnDialogs +hWndhScriptGui -Theme"
Menu GameMenu, Add, Start Game, MenuActions
Menu GameMenu, Add, Quit Game, MenuActions
Menu GameMenu, Add
Menu GameMenu, Add, Add New Game, MenuActions
Menu Menu, Add, &Game, :GameMenu
Menu OptionsMenu, Add, Toggle Tooltips off, MenuActions
Menu OptionsMenu, Add, Toggle Admin, MenuActions
Menu OptionsMenu, Add, Toggle OnTop, MenuActions
Menu OptionsMenu, Add
Menu OptionsMenu, Add, Show Game List, MenuActions
Menu Menu, Add, &Options, :OptionsMenu
Menu ScriptMenu, Add, Reset Script, MenuActions
Menu ScriptMenu, Add, Reload Script, MenuActions
Menu ScriptMenu, Add
Menu ScriptMenu, Add, Add/Edit Code, MenuActions
Menu ScriptMenu, Add, Spy Glass, MenuActions
Menu Menu, Add, &Script, :ScriptMenu
Gui Menu, Menu

Gui Add, CheckBox, x368 y1 w10 h10 Checked%ShowGameList% vShowGameList gShowGameList -theme +0x1020 +E0x20000
Gui Add, GroupBox, x8 y0 w362 h194 +Center, % Admin ? "" : DropNotice
Gui Add, GroupBox, x16 y8 w345 h64
Gui Font, s10 Bold
Gui Add, Text, x80 y40 w276 +0x200 vTitle, %Title%
Gui Font
Gui Add, Picture, x20 y18 w50 h50 +0x09 vPic, % "HICON:*" hIcon := LoadPicture(FullPath, "GDI+ Icon1 w50", ImageType)
Gui Add, Button, x307 y18 w50 h18 vBrowse, Browse
Gui Add, Button, x16 y160 w70 h23 vRunGame, &Start Game
Gui Add, Button, x88 y160 w70 h23 vOpenFolder, Open Folder
Gui Add, Button, x304 y160 w60 h23 gGuiClose, Exit
Gui Add, GroupBox, x16 y72 w345 h83
Gui Add, Text, x24 y80 w99 h14, Autowalk keys
Gui Add, Edit, x24 y100 w63 h21 Limit1 -TabStop vhKey, %hKey%
Gui Add, Edit, x24 y126 w63 h21 Limit1 -TabStop vskey, %skey%
Gui Add, CheckBox, x120 y104 w82 h23 Checked%RPGGames% vRPGGames gRPGGames, RPG Games
Gui Add, CheckBox, x120 y128 w82 h23 +Disabled Checked%TurnCamera% vTurnCamera gTurnCamera, Turn Camera
Gui Add, Edit, x212 y128 w60 h21 +Disabled Limit1 -TabStop vLeftKey, %LeftKey%
Gui Add, Edit, x280 y128 w60 h21 +Disabled Limit1 -TabStop vRightKey, %RightKey%
Gui Add, GroupBox, x376 y0 w154 h193 +Hidden vGBGameList
Gui Add, ListView, x384 y16 w137 h169 vListviewActions gListviewActions hWndhLVItems -ReadOnly +Hidden, Window Title

if (RPGGames) {
    GuiControl([["Enable", "TurnCamera"]])
    if (TurnCamera = 1) {
        GuiControl([["Enable", "LeftKey"], ["Enable", "RightKey"]])
    }
}

For MenuItemTxt, VariableName in MenuItems
{
    if (%VariableName%) {
       Menu OptionsMenu, ToggleCheck, % MenuItemTxt
   }
}

LoadIcons()

if (ShowGameList) {
    GuiControl([["Show", "GBGameList"], ["Show","ListviewActions"]])
    Gui Show, % "w" (Gui_W := 538) " h201 x" Gui_X " y" Gui_Y, AutoWalk
} else {
    Gui Show, % "w" (Gui_W := 378) " h201 x" Gui_X " y" Gui_Y, AutoWalk
}

OnMessage(Wm_MouseMove, "WM_Mouse")
OnMessage(Wm_LbuttonDown, "WM_Mouse")
OnMessage(Wm_DraggGui, "WM_Mouse")
OnExit("SaveSettings")
Return

;_______________________________________ Game Specific Code _______________________________________

; When this file "UserCode.ahk" resides in the same folder as where the script is.
; Then the code in that file is used by this script when the game window is active.
; Read comment on function ButtonSingleDouble() for more instructions.
;
#IfWinExist ahk_group ClientGroup
#IfWinActive ahk_group ClientGroup
#Include *i UserCode.ahk
Return

;_______________________________________ Script Lables _______________________________________


HotKeyAutoWalk:
    AutoWalk(sKey)
Return

MenuActions:
    ; Check or uncheks menuitems. Then toggles the value for the variable that is accosiated
    ; with the menuitem to the opesite. Saves or remove the variable to/from ini file.
    If (A_ThisMenu = "GameMenu") {
        If (A_ThisMenuItem = "Start Game") {
            Gosub, ButtonStartGame
        }
        else if (A_ThisMenuItem = "Quit Game") {
            WinClose, ahk_class %ClientGuiClass%
            Reload()
        }
        else if (A_ThisMenuItem = "Add New Game") {
            Gosub ButtonBrowse
        }
    }
    else If (A_ThisMenu = "OptionsMenu") {
        For MenuItemTxt, VariableName in MenuItems
        {
            If (A_ThisMenuItem = MenuItemTxt) {
                Menu %A_ThisMenu%, ToggleCheck, %MenuItemTxt%

                if (%VariableName% := %VariableName% ? 0 : 1) {
                    IniWrite, % %VariableName%, %ConfigFile%, Settings, %VariableName%
                } else {
                    IniDelete, %ConfigFile%, Settings, %VariableName%
                }
            }
        }
        If (A_ThisMenuItem = "Toggle Admin") {
            Admin ? Reload() : ExitApp()
        }
        else If (A_ThisMenuItem = "Toggle OnTop") {
            Gui % (OnTop ? "+" : "-") "AlwaysOnTop"
        }
        else If (A_ThisMenuItem = "Show Game List") {
            if (ShowGameList) {
                WinMove, AutoWalk,,,, 538
                GuiControl([["Show", "GBGameList"], ["Show","ListviewActions"], ["", "ShowGameList", ShowGameList]])
            } else {
                GuiControl([["Hide", "GBGameList"], ["Hide","ListviewActions"], ["", "ShowGameList", ShowGameList]])
                WinMove, AutoWalk,,,, 384
            }
        }
    }
    else If (A_ThisMenu = "ScriptMenu") {
        If (A_ThisMenuItem = "Reset Script") {
            SaveSettings()
            If (FileExist(A_ScriptDir "\UserCode.ahk")) {
                FileCopy, % A_ScriptDir "\UserCode.ahk", % UserCodeFiles "\" Title ".ahk", 1
                FileDelete % A_ScriptDir "\UserCode.ahk"
            }
            FileDelete %ConfigFile%
            Admin ? Reload() : ExitApp()
        }
        Else if (A_ThisMenuItem = "Reload Script") {
            Reload
        }
        else If (A_ThisMenuItem = "Add/Edit Code") {
            if (!DefaultEditor) {
                RegRead, DefaultEditor, HKEY_CLASSES_ROOT\AutoHotkeyScript\Shell\Edit\Command
                Clipboard := DefaultEditor
                if (ErrorLevel) {
                    MsgBox, 0x24, Missing default editor, % "It seems you're machine hase no default editor installed.`nDo you wish to select one?`n`nYes:`nFile association for *.ahk files will be configured for you're chosen tool.`n`nNo:`nThe script will use notepad to edit *.ahk files."

                    IfMsgBox Yes, {
                        FileSelectFile DefaultEditor, 2,, Select your editor, Programs (*.exe, *.ahk)
                        if ErrorLevel
                            return
                        RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, "%DefaultEditor%" "`%1"
                    }
                    Else IfMsgBox No, {
                        RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, "Notepad.exe" "`%1"
                    }
                }
                Else if (!ErrorLevel) {
                    MsgBox, 0x23, Use default editor, % "You are using " StrReplace(SubStr(DefaultEditor,InStr(DefaultEditor,"\",,0,1)+1), """ ""`%1""") " as you're default editor.`nDo you want the script to also use it for editing?`n`nNo to select a different editor."
                    IfMsgBox Yes, {
                        IniWrite, % StrReplace(DefaultEditor, """" `%1 """"), %ConfigFile%, Settings, DefaultEditor
                    } else IfMsgBox No, {
                        FileSelectFile DefaultEditor, 2,, Select your editor, Programs (*.exe, *.ahk)
                        if ErrorLevel
                            return
                        RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, "%DefaultEditor%" "`%1"
                    } Else IfMsgBox Cancel, {
                        Return
                    }
                }
                FileAppend, ExitApp`nreturn`n, %A_ScriptDir%\UserCode.ahk
            }
            Run %DefaultEditor% UserCode.ahk
        }
        Else if (A_ThisMenuItem = "Spy Glass") {

            if (OnTop)
                Gui -AlwaysOnTop

            OnMessage(0x44, "OnMsgBox")
            MsgBox 0x80, ToDo: ?, Not Implemented yet, 4
            OnMessage(0x44, "")

            if (OnTop)
                Gui +AlwaysOnTop
        }
    }
    else If (A_ThisMenu = "LvMenu") {
        if (A_ThisMenuItem = "Change Title") {
            InputBox NewTitle, Change Title, Enter a new title below.,,,132,,,,, %GameTitle%
            if (!ErrorLevel && NewTitle) {
                LV_Modify(EventInfo, "Text", NewTitle)

                if (GameTitle = Title) {
                    GuiControl([[ , "Title", NewTitle]]), Title := NewTitle, NewTitle := ""
                    IniWrite %Title%, %ConfigFile%, Settings, Title
                } else {
                    Loop, parse, % F := FileOpen(Profiles, 0).read(), `n, `r
                    {
                        f.Seek(StrLen(A_LoopField),0)

                        MsgBox,,1, % f.Tell()
                        if ((InStr(A_LoopField, "[",, 1, 1)) = 1) {
                            SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
                        MsgBox,,2, % f.Tell()
                        } Else if (GameTitle = SectionName) {
                            MsgBox,,3, % f.Tell()

                        }
                    }

                }
            }
        }
    }
Return

/*
LVM_SETITEMTEXTA := 0x102E
DubItem := ""
SetTxt := ""

SendMessage 0x102E, HwndLV, DubItem,, ahk_id %hWnd% ; LVM_SETITEMTEXTA
SendMessage 0x102D, HwndLV, lParam,, ahk_id %hWnd% ; LVM_GETITEMTEXTA
*/

ListviewActions:
    Loop {
        if (!(RowNumber := LV_GetNext(RowNumber)))
            break
        LV_GetText(GameTitle, RowNumber)
    }
    if (!GameTitle)
        Return

    Gui -AlwaysOnTop
    if (A_GuiEvent == "DoubleClick") {
        MsgBox,0x24, Load new settings, % "Do you want to load the settings for this game:`n " GameTitle ""
        IfMsgBox Yes
        {
            If (FileExist(ConfigFile)) {
                FileDelete %ConfigFile%
            }
            If (FileExist(A_ScriptDir "\UserCode.ahk")) {
                FileCopy, % A_ScriptDir "\UserCode.ahk", % UserCodeFiles "\" Title ".ahk", 1
                FileDelete % A_ScriptDir "\UserCode.ahk"
            }
            If (FileExist(Profiles)) {
                Loop, parse, % FileOpen(Profiles, 0).read(), `n, `r
                {
                    if ((InStr(A_LoopField, "[",, 1, 1)) = 1) {
                        SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")

                    } Else if (GameTitle = SectionName) {
                        VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
                        if (%VarRef%)
                            IniWrite, % %VarRef%, %ConfigFile%, Settings, %VarRef%
                    }
                }
                If (FileExist(UserCodeFiles "\" GameTitle ".ahk")) {
                    FileCopy, % UserCodeFiles "\" GameTitle ".ahk", % A_ScriptDir "\UserCode.ahk", 1
                }
                Reload()
            }
        }
    }
    Gui % (OnTop ? "+" : "-") "AlwaysOnTop"
return

LV_EX_GetSubItemText(HLV, Row, Column := 1, MaxChars := 257) {
   ; LVM_GETITEMTEXT -> http://msdn.microsoft.com/en-us/library/bb761055(v=vs.85).aspx
   Static LVM_GETITEMTEXT := A_IsUnicode ? 0x1073 : 0x102D ; LVM_GETITEMTEXTW : LVM_GETITEMTEXTA
   Static OffText := 16 + A_PtrSize
   Static OffTextMax := OffText + A_PtrSize
   VarSetCapacity(ItemText, MaxChars << !!A_IsUnicode, 0)
   LV_EX_LVITEM(LVITEM, , Row, Column)
   NumPut(&ItemText, LVITEM, OffText, "Ptr")
   NumPut(MaxChars, LVITEM, OffTextMax, "Int")
   SendMessage, % LVM_GETITEMTEXT, % (Row - 1), % &LVITEM, , % "ahk_id " . HLV
   VarSetCapacity(ItemText, -1)
   Return ItemText
}
LV_EX_LVITEM(ByRef LVITEM, Mask := 0, Row := 1, Col := 1) {
   Static LVITEMSize := 48 + (A_PtrSize * 3)
   VarSetCapacity(LVITEM, LVITEMSize, 0)
   NumPut(Mask, LVITEM, 0, "UInt"), NumPut(Row - 1, LVITEM, 4, "Int"), NumPut(Col - 1, LVITEM, 8, "Int")
}

GuiDropFiles:
    Loop, parse, A_GuiEvent, `n, `r
        FullPath := A_LoopField, Path := SubStr(A_LoopField, 1, InStr(A_LoopField, "\", ,-1)-1), ExeFile := SubStr(A_LoopField, InStr(A_LoopField, "\", ,-1)+1)

ButtonBrowse:
    If ((A_ThisLabel = "ButtonBrowse") | (A_ThisMenuItem = "Add New Game")) {
        FileSelectFile, FullPath, M3, , ,*.exe
        Loop, parse, % FullPath, `n, `r
            A_Index <= 1 ? Path := A_LoopField : ExeFile := A_LoopField
        if (ErrorLevel)
            Exit
    }

    FileGetSize, fileSize, %FullPath%, K
    if ((FileSize < 1024) & (FileSize != ""))
        MsgBox,,FileSize: %FileSize% KB, % "The size of you're file is less then 1MB`n`nAre you sure this is the real exe and not a shortcut`nto a ecxecutable some folders below`n`nFile size: " FileSize "KB"

    If (FileExist(ConfigFile))
        FileDelete %ConfigFile%

    IniWrite % Admin := 1, %ConfigFile%, Settings, Admin
    IniWrite % TipsOff := 1, %ConfigFile%, Settings, TipsOff
    IniWrite % FullPath := Trim(Path) "\" Trim(ExeFile), %ConfigFile%, Settings, FullPath
    IniWrite %Path%, %ConfigFile%, Settings, Path
    IniWrite %ExeFile%, %ConfigFile%, Settings, ExeFile
    IniWrite % Title := "Ready to start you're game", %ConfigFile%, Settings, Title
    IniWrite % OnTop := 0, %ConfigFile%, Settings, OnTop
    Reload()
Return

ButtonStartGame:
    If ((Title > 0) & (InStr(Title ,"Ready to start you're game") = 0)) {
        If (!(HwndClient := WinExist("ahk_class " ClientGuiClass))) {
            Run %FullPath%, %Path%
        }
        WinWait ahk_class %ClientGuiClass%
        WinGet S, Style
        WinGet ExS, ExStyle

        ; Remove AlwaysOnTop from a fullscreen window. It's anoying behavier.
        if ((S = FullScreen) & (ExS = AppwindowAlwaysOnTop)) {
            WinSet, ExStyle, % "-" WS_EX_TOPMOST, ahk_class %ClientGuiClass%
        }

        WinActivate ahk_class %ClientGuiClass%
        WinSet Top,, ahk_class %ClientGuiClass%

        ; Skip creating group and hotkey again once the game is launched.
        if (!ClientGroup, ClientGroup := 1) {
            GroupAdd ClientGroup, ahk_class %ClientGuiClass%
            Hotkey IfWinActive, ahk_class %ClientGuiClass%
            Hotkey ~%hKey%, HotKeyAutoWalk, On
        }
    }
    Else If (Title = "Ready to start you're game") {
        Text := "WAIT UNTIL THE MAIN GAME WINDOW IS FULLY LOADED!`n`nThen press escape to close this window even if you don't see it anymore!`n"

        WinSet, Bottom,, AutoWalk
        Gui 1:+Disabled

        Gui ClipMsg:+LastFound +AlwaysOnTop hwndhClipMsg -border -Caption -SysMenu
        Gui ClipMsg:Margin, 10, 12
        Gui ClipMsg:font, c0xFFFFFF s%FontSize%
        Gui ClipMsg:color, 0x000000
        Gui ClipMsg:Add, Text, r4, %Text%
        Gui ClipMsg:Show, % "Y" (A_ScreenHeight // 4), ClipMsg
        WinSet, Transparent, 210, ahk_id %hClipMsg%

        Hotkey, IfWinExist, ClipMsg
        Hotkey, ~*Vk1B, ClipMsgEscape, On   ; Vk1B = Escape
        
        sleep 5000
        Run %FullPath%, %Path%
        WinWaitClose, ClipMsg
        GoSub, ButtonStartGame
        Return

        ClipMsgEscape:
            Keywait()
            Hotkey, ~*Vk1B, ClipMsgEscape, Destroy
            Gui ClipMsg:Destroy
            Gui 1:-Disabled

            WinGetTitle, Title, ahk_exe %ExeFile%
            WinGetClass, ClientGuiClass, ahk_exe %ExeFile%

            IniWrite %Title%, %ConfigFile%, Settings, Title
            IniWrite %ClientGuiClass%, %ConfigFile%, Settings, ClientGuiClass

            GuiControl([[ , "Title", Title]])
            
            ;GroupAdd, ClientGroup, ahk_class %ClientGuiClass%
        Return
    }
    Else if (!Title) {
        Return
    }
Return

ButtonOpenFolder:
    KeyWait("LButton")
    If ((GetKeyState("LControl", "P")) | (GetKeyState("RControl", "P"))) {
        Run, Explorer.exe "%A_ScriptDir%"
    } else {
        Run, Explorer.exe "%Path%"
    }
Return

ShowGameList:   ; Checkbox
    Menu OptionsMenu, ToggleCheck, Show Game List

    if (ShowGameList := ShowGameList ? 0 : 1) {
        WinMove, AutoWalk,,,, 538
        GuiControl([["Show", "GBGameList"], ["Show","ListviewActions"]])
        IniWrite, %ShowGameList%, %ConfigFile%, Settings, ShowGameList
    } else {
        GuiControl([["Hide", "GBGameList"], ["Hide","ListviewActions"]])
        WinMove, AutoWalk,,,, 384
        IniDelete, %ConfigFile%, Settings, ShowGameList
    }
Return

RPGGames:   ; Checkbox
    GUI, submit, nohide

    if (RPGGames) {
        GuiControl([[ , "hKey", "LButton"], [ , "sKey", "LButton"], ["Enable", "TurnCamera"]])
        IniWrite, %RPGGames%, %ConfigFile%, Settings, RPGGames
        IniWrite, % hKey := "LButton", %ConfigFile%, Settings, hKey
        IniWrite, % sKey := "LButton", %ConfigFile%, Settings, sKey
    } else {
        ;TurnCamera := ""
        GuiControl([["enable", "hKey"], ["Disable", "TurnCamera"], ["Disable", "LeftKey"], ["Disable", "RightKey"], [ , "TurnCamera", "0"]])
        IniDelete, %ConfigFile%, Settings, TurnCamera
        IniDelete, %ConfigFile%, Settings, RPGGames
    }
    GUI, submit, nohide
Return

TurnCamera: ; Checkbox
    GUI, submit, nohide

    if (TurnCamera) {
        GuiControl([["Enable", "LeftKey"], ["Enable", "RightKey"]])
        IniWrite, %TurnCamera%, %ConfigFile%, Settings, TurnCamera
    } else {
        GuiControl([["Disable", "LeftKey"], ["Disable", "RightKey"]])
        IniDelete, %ConfigFile%, Settings, TurnCamera
    }
    GUI, submit, nohide
Return

GuiEscape:
GuiClose:
    ExitApp

;_______________________________________ Script Functions _______________________________________

AutoWalk(sKey) {
    Static KeyState

    ; When enabled, you need to press the hotkey twice to trigger the key to send.
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
            } Else if (KeyState = "Up") {
                Hotkey, ~*Vk057, InterruptDownState, OFF
                Hotkey, ~*Vk01, InterruptDownState, OFF
            }
        Return
    }
    Return
}

LoadIcons() {
    Global

    Loop, parse, % FileOpen(Profiles, 0).read(), `n, `r
    {
        if ((InStr(A_LoopField, "[",, 1, 1)) = 1) {
            i += 1, SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
            IniRead, Iconfile%i%, %Profiles%, %SectionName%, FullPath
            IconLib[i, 1] := Iconfile%i%
            IconLib[i, 2] := SectionName
        }
    }
    i := 0, IconList := IL_Create(IconLib.Length())
    LV_SetImageList(IconList)

    loop % IconLib.Length()
    {
        IL_Add(IconList, IconLib[A_Index, 1])
        LV_Add("Icon" . A_Index, IconLib[A_Index, 2])
    }
    LV_ModifyCol("Hdr")
}


GuiContextMenu(GuiHwnd, CtrlHwnd, E, IsRightClick, X, Y) {
    Global hLVItems, EventInfo := E, GameTitle

    if (CtrlHwnd = hLVItems) {
        LV_GetText(GameTitle, EventInfo)
        menu, LVMenu, add, Delete %GameTitle%, MenuActions
        menu, LVMenu, add, Change Title, MenuActions
        menu, LVMenu, add
        menu, LVMenu, add, Hide listview, MenuActions
        Menu, LVMenu, Show, %x%, %y%
    }
}

; Read ini file and create variables. Sections are supported.
; Referenced variables are not local to functions. So %VarRef% represents global
; variables to which some value is added %VarRef% := "ValueOfVar"
;
iniRead(InputFile, LoadSection = 0) {
    if (LoadSection) {
        if (IsObject(LoadSection)) {                                            ; Load multiple sections from object
             for i, Name in LoadSection
             {
                Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
                {
                    if (InStr(A_Loopfield, Name)) {
                        SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
                        Continue
                    }
                    if (SectionName) {
                        if (((InStr(A_LoopField, "[",, 1, 1)) = 1) | ((InStr(A_LoopField, "`;",, 1, 1)) = 1) | (!A_LoopField)) {
                            if (((InStr(A_LoopField, "`;",, 1, 1)) = 1) | (!A_LoopField)) {
                                Continue
                            } else {
                                SectionName := ""
                                break
                            }
                        }
                        VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
                    }
                }
            }
        }
        Else if (!IsObject(LoadSection)) {
            if ((InStr(LoadSection, " ")) > 1) {                                ; Load multiple sections
                Sections := []
                Loop, Parse, LoadSection, " ", A_Space
                    Sections[A_Index] := A_Loopfield
                for i, Name in Sections
                {
                    Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
                    {
                        if (InStr(A_Loopfield, Name)) {
                            SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
                            Continue
                        }
                        if (SectionName) {
                            if (((InStr(A_LoopField, "[",, 1, 1)) = 1) | ((InStr(A_LoopField, "`;",, 1, 1)) = 1) | (!A_LoopField)) {
                                if (((InStr(A_LoopField, "`;",, 1, 1)) = 1) | (!A_LoopField)) {
                                    Continue
                                } else {
                                    SectionName := ""
                                    break
                                }
                            }
                            VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
                        }
                    }
                }
            } Else {                                                        ; Load single section
                Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
                {
                    if (InStr(A_Loopfield, LoadSection)) {
                        SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
                        Continue
                    }
                    If (SectionName) {
                        if ((InStr(A_LoopField, "[",, 1, 1)) = 1)
                            Break
                        VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
                    }
                }
            }
        }
    }
    Else if (!LoadSection) {                                              ; Load all variables from ini
        Loop, parse, % FileOpen(InputFile, 0).read(), `n, `r
        {
            if (((InStr(A_LoopField, "[",, 1, 1)) = 1) | ((InStr(A_LoopField, "`;",, 1, 1)) = 1) | (!A_LoopField))
                Continue
            VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %VarRef% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
        }
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

; Returns the last hotkey used with all modifiers removed from it.
ThisHotKey() {
    Return RegExReplace(A_ThisHotkey, "[~\*\$]")
}

/*
    GuiControl as a function for more flexible usage. Parameter ControlID can be a array.
    For example, if you want to use the GuiControl command 3 times in a row.
    Then the array should look something like:
    ControlID := [[SubCommand, ControlID, Value], [SubCommand, ControlID], [ , ControlID, Value]]

    You can also insert objects directly on the parameter for ControlID.
    GuiControl([[SubCommand, ControlID, Value], [SubCommand, ControlID], [ , ControlID, Value]])

    Command options. See ahk manual for details.

    • (Blank): Puts new contents into the control.
    • Text: Changes the text/caption of the control.
    • Move: Moves and/or resizes the control.
    • MoveDraw: Moves and/or resizes the control and repaints the region occupied by it.
    • Focus: Sets keyboard focus to the control.
    • Disable: Disables (grays out) the control.
    • Enable: Enables the control.
    • Hide: Hides the control.
    • Show: Shows the control.
    • Delete: Not yet implemented.
    • Choose: Selects the specified item number in a multi-item control.
    • ChooseString: Selects a item in a multi-item control whose leading part matches a string.
    • Font: Changes the control's font typeface, size, color, and style.
    • Options: Add or remove various control-specific or general options and styles.
*/
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

    if (msg = WM_MOUSEMOVE) {
        If (SpyGlass = 1) {
            MouseGetPos, now_x, now_y
            now_x -= 75
            now_y -= 75
            WinMove, Magnifier, , %now_x%, %now_y%
            ToolTip % now_x "  " now_y
        }
        if (!TipsOff) {
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
        if ((GetKeyState("LButton", "P")) & (!A_GuiControl) & (WinActive("A") != hClipMsg)) {
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
    Hotkey, IfWinActive, AutoWalk
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
            If (!InStr(ControlBelowMouse, "Edit") & InStr(ControlOldBelowMouse, "Edit")) {
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
    } Else if (!WaitRelease) {
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
    } Else if (dragg = 0) {
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

; Reload() and below that exit(), Exit or close the script without calling function SaveSettings() first.
Reload() {
    If (A_IsCompiled) {
        Run "%A_ScriptFullPath%" /restart
    } Else {
        Run "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp()
}
ExitApp() {
    OnExit("SaveSettings", 0)
    ExitApp
}

; This is called right before the script terminates. It saves the position of the GUI and copies
; all current variables from the settings.ini to \GameProfiles\GamesConfig.ini.
; GamesConfig.ini contains all variables from the previous used games.
;
SaveSettings() {
    WinGetPos, Gui_X, Gui_Y, ,, AutoWalk

     ; Remember the position of the script GUI when it's not somewhere outside the display.
    if ((Gui_X > -1) & (Gui_Y > -1)) {
        IniWrite, %Gui_X%, %ConfigFile%, Settings, Gui_X
        IniWrite, %Gui_Y%, %ConfigFile%, Settings, Gui_Y
    }

    ; When the window title is the title of the game window.
    if ((Title) && (Title != "Ready to start you're game")) {
        If (!FileExist(Profiles)) {
            FileCreateDir, GameProfiles
            FileAppend,, %Profiles%
        }
        ; Save all values from Settings.ini to the Profiles.ini file
        Loop, parse, % FileOpen(ConfigFile, 0).read(), `n, `r
        {
            if (InStr(A_Loopfield, "[")) {
                SectionName := StrReplace(A_Loopfield, "["), SectionName := StrReplace(SectionName, "]")
                IniDelete, %Profiles%, %Title%
                FileAppend, % "[" Title "]", %Profiles%
            }
            Else If (SectionName && A_LoopField) {
                VarRef := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1)
                IniWrite, % %VarRef%, %Profiles%, %Title%, %VarRef%
            }
        }
    }
}

OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        hIcon := LoadPicture("shell32.dll", "w32 Icon270", _)
        SendMessage 0x172, 1, %hIcon%, Static1 ; STM_SETIMAGE
    }
}
