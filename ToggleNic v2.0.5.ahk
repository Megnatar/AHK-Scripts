; ToggleNic V2.0.5
; This script is wriitten with the aid of AUtoGui. thanx guy's!


#NoEnv
#SingleInstance off
#NoTrayIcon
DetectHiddenWindows on
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
ListLines off

if (!A_IsAdmin) {
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


; --------------------------------------- Script Functions ---------------------------------------

DisableNet() {

    if (!InStr(A_IPAddress1, "127.0") || !InStr(A_IPAddress1, "169.254")) {
    
        Menu, tray, Icon, % IconFile, % IconNoNetwork
        Menu, tray, Tip, % "No Network"
        
        Run, %ComSpec% /c "Ipconfig /release Ethernet*", , Hide
    
        while (InStr(A_IPAddress1, "192.168"))
            sleep 10
            
        Menu, tray, Icon, % IconFile, % IconDisabled
        Menu, tray, Tip, % "Disabled"

    } else {
    
        Menu, tray, Icon, % IconFile, % IconDisabled
        Menu, tray, Tip, % "Disabled"
    }
}

EnableNet() {
 
    if (!InStr(A_IPAddress1, "192.168")) {
        
        Menu, tray, Icon, % IconFile, % IconNoNetwork
        Menu, tray, Tip, % "No Network"
        
        Run, %ComSpec% /c "Ipconfig /renew Ethernet*", , Hide
    
        while (InStr(A_IPAddress1, "127.0") || InStr(A_IPAddress1, "169.254"))
            sleep 10
        
        Menu, tray, Icon, % IconFile, % IconEnabled
        Menu, tray, Tip, % LocalAreaNetwork > 0 ? WanIp : ipv4
        
    } else {
    
        Menu, tray, Icon, % IconFile, % IconEnabled
        Menu, tray, Tip, % LocalAreaNetwork > 0 ? WanIp : ipv4

    }
}

QueryNic() {

    DevInfo := Wmi.ExecQuery("SELECT * FROM Win32_NetworkAdapter where PhysicalAdapter = true")._NewEnum()
    while DevInfo[i] {
        Mac := i.MACAddress, Name := i.Name, DeviceID := i.DeviceID
    }
    
    for i in wmi.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Index=" DeviceID) {
        Ip := i.IpAddress[0], DNSServer1 := i.DNSServerSearchOrder[0], DNSServer2 := i.DNSServerSearchOrder[1]
        DNSServer := InStr(DNSServer1, "192.168") ? DNSServer2 : DNSServer1
    }
    Return {"ipv4": Ip, "WanIp": GetWanIp(DNSServer), "DNSServer": DNSServer, "NetworkCard": Name, "DeviceID": DeviceID, "Mac": Mac }
}

GetWanIp(pDnsIp) {
    
    Local
    
    ClipBrdOld := Clipboard
    
    WaitConnectISP:
    Clipboard := ""
    RunWait, %ComSpec% /c "ping -n 1 -r 1 %pDnsIp% | clip", , Hide

    Loop, parse, % Clipboard, `n, `r
    {
        if (A_Index = 4) {
        
            if (!(WanIp := Trim(SubStr(A_LoopField, 12), " `t`n`r"))) {
                Gosub, WaitConnectISP
                break
            }
            else if (WanIp > 0) {
                Clipboard := ClipBrdOld  
                
               
            }
        }
    }
     return WanIp
}

GetNetSpeed(GetState=0, GetName=0) {

    local MIB_IF_ROW2, IfIndex
    
    ; Create interface structure and use the default network device.
    VarSetCapacity(MIB_IF_ROW2, 1368, 0)
    DllCall("iphlpapi\GetBestInterface", "Ptr", 0, "Ptr*", IfIndex)
    NumPut(IfIndex, &MIB_IF_ROW2+8, "UInt")
    NumPut(&MIB_IF_ROW2+1256, &MIB_IF_ROW2+1352), NumPut(&MIB_IF_ROW2+1320, &MIB_IF_ROW2+1360) ; InUcastOctets/OutUcastOctets


    ; Get/Refresh structure data.
    DllCall("iphlpapi\GetIfEntry2", "Ptr", &MIB_IF_ROW2)
    
    ; Return bytes In/Out
    return {1: NumGet(NumGet(&MIB_IF_ROW2+1352), "Int64"), 2: NumGet(NumGet(&MIB_IF_ROW2+1360), "Int64")}
}

AHKGroupEX(Remove:=0, AddApp*) {
    Static Apps := []
    
    if (Remove) {
        Apps.RemoveAt(Remove, Apps.Length(Apps[Remove]))
    }
    else if (Apps.Length() < 1) {
        i := 1
    
        ParseFile:
        Loop, parse, % FileOpen(A_ScriptDir "\NetAccess.acc", 0).read(), `n, `r`n
        {
            If (A_LoopField) {
                Apps[(i++)] := Trim(A_LoopField, " `t`r`n"), Size := A_Index
            } else {
                Continue, ParseFile
    }   }   }
    else if (AddApp.Length() > 0) {
        for i, App in AddApp {
            Apps.InsertAt(Apps.Length()+i, "ahk_exe " App)
            FileAppend, % "ahk_exe " App "`n", %A_ScriptDir%\NetAccess.acc
    } }
    Return Apps
}

ToggleAutoToggle(StartUp := 0) {
    Global
    
    local i
    if (StartUp = 1) {
        ShellMessage(1, "StartUp")
        Menu, tray, Tip, %WanIp%`nAutoToggle = Off
        Menu, tray, Icon, % IconFile, % IconEnabled
        
    } else {
    
        i := (ToggleNew = ToggleOff), i > 0 ? (ToggleNew := ToggleOn, ToggleOld := ToggleOff, tt := WanIp "`nAutoToggle = Off", OnMessage(MsgID,""), AutoToggle := 0, EnableNet()) : (ToggleNew := ToggleOff, ToggleOld := ToggleOn, tt := WanIp, OnMessage(MsgID, "ShellMessage"), AutoToggle := 1, (i := WindowExist(Applist)) < 1 ? DisableNet())
        
        if (i = 0)
            Gui hide
            
        Menu, tray, Tip, % tt
        Menu, tray, rename, %ToggleOld%, %ToggleNew%
        IniWrite, %AutoToggle%, % A_ScriptDir "\Settings.ini", Settings, AutoToggle
}   }

WindowExist(A) {

    for i, v in A {
        if (hWmd := WinExist(v)) {
            return hWmd
    }   }
    return 0
}

/* About GuiUpdate()
 When parm1 in List* is a object, input format should be as following.
 Parm1 is the object holding the Gui's.
  Object1 looks like: {1: "Gui1", 2: "Gui2"}

 Parm2 and greater are the objects for the parameters.
 Where Object2 are the parmeters for Gui1, object3 for Gui2 and so on.
  Object2 looks like: {1: "Parm1"}
  Object3 looks like {1: "Parm1", 2: "Parm2"}

 Command:
 GuiUpdate({1: "Gui1", 2: "Gui2"}, {1: "Parm"}, {1: "Parm", 2: "Parm"}) or
 GuiUpdate(GuiObj1, ParmObj2, ParmObj3) <- To update a single gui

 And when parm1 in object List* is a string, then it's value should be the name
 of the gui to update.

 Command:
  GuiUpdate("MyGui", "Parm1", "Parm2", ...)
*/

GuiUpdate(List*) {

    if (IsObject(List[1])) {
        for indx, GuiId in List[1] {
            for i, P in List[indx+1] {
                if (P = "Submit") {
                    Gui % GuiId ":" P, NoHide
                } 
                else {
                    Gui % GuiId ":" P
    }   }   }   }
        
    else {
        for i, P in List {
            if (!GuiId) {
                GuiId := P
            }
            else if (GuiId) {
                if (P = "Submit") {
                    Gui % GuiId ":" P, NoHide
                } 
                else {
                    Gui % GuiId ":" P
}   }   }   }   }

GuiControl(cmd:="", CtrlId:="", Parm:="", A*) {
    SetControlDelay -1
    Critical
    
    if IsObject(A[1]) {
        for i, CtrlId in A[1] {
            for indx, Parm in A[i+1] {            
                if (A[i+1].Length() = 1) {
                    GuiControl, , %CtrlId%, %Parm%
                }
                else if (A[i+1].Length() = 2) {
                    if (indx = 1)
                        cmd :=  Parm
                    else if if (indx = 2)
                        GuiControl, %cmd%, %CtrlId%, %Parm%
    }   }   }   }
    
    else if (!cmd && Parm) {
        GuiControl, , %CtrlId%, %Parm%
        
    } Else if (cmd && !parm) {
        GuiControl, %cmd%, %CtrlId%
        
    } Else if (cmd && parm) {
        GuiControl, %cmd%, %CtrlId%, %P%
    }
    return ErrorLevel
}

LoadLibraries(LibFiles*) {
    Modules := []
    
    for i, LibFiles in LibFiles {
        if (InStr(LibFiles, "gdiplus")) {
            VarSetCapacity(Size, A_PtrSize = 8 ? 24 : 16, 0), Size := Chr(1)
            DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pTo, A_PtrSize ? "UPtr" : "UInt", &Size, Ptr, 0)
            Modules[i, 1] := DllCall("LoadLibrary", "str", "gdiplus"), Modules[i, 2] := pTo, Modules[i, 3] := SubStr(LibFiles, 1, InStr(LibFiles, ".")-1)
        } else {
            Modules[i, 1] := DllCall("LoadLibrary", "Str", LibFiles, "Ptr"), Modules[i, 2] := 0, Modules[i, 3] := SubStr(LibFiles, 1, InStr(LibFiles, ".")-1)
        } }
    return Modules
}

FreeLibraries(Modules*) {

    For i, Modules in Modules
        DllCall("FreeLibrary", "Ptr", Modules[i, 1])
    Return 0
}

CreateFocusRec(CtrlhWnd, WinHwnd, Clr) {
    Critical

    SetControlDelay -1
    
    GuiControlGet c, Pos, %CtrlhWnd%

    Gui, GdiLayer: -Caption +E0x80000 +LastFound +AlwaysOnTop hwndhGdiLayer
    Gui, GdiLayer: Show, NA

    DllCall("SetParent", "uint", hGdiLayer, "uint", WinHwnd)
    
    ; Rectangle structure, only need x and y here
    VarSetCapacity(Rect, 8)
    NumPut(cX, Rect, 0, "UInt"), NumPut(cY, Rect, 4, "UInt")

    ; Bitmap structure.
    VarSetCapacity(Bitmap, 40, 0)
    NumPut(40, Bitmap, 0, "uint"), NumPut(cW, Bitmap, 4, "uint")
    NumPut(cH, Bitmap, 8, "uint"), NumPut(1, Bitmap, 12, "ushort")
    NumPut(32, Bitmap, 14, "ushort"), NumPut(0, Bitmap, 16, "uInt")
    
    ; Use x64 or win32 pointers?
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    PtrA := A_PtrSize ? "UPtr*" : "Uint*"
    
    ; Create Mem Bitmap.
    dc := DllCall("GetDC", Ptr, CtrlhWnd, "Ptr")
    hbm := DllCall("CreateDIBSection", Ptr, dc, Ptr, &Bitmap, "uint", 0, PtrA, 0, Ptr, 0, "uint", 0, "Ptr")
    hdc := DllCall("CreateCompatibleDC", Ptr, dc)
    obm := DllCall("SelectObject", Ptr, hdc, Ptr, hbm)
    DllCall("gdiplus\GdipCreateFromHDC", Ptr, hdc, PtrA, G)
    DllCall("gdiplus\GdipSetSmoothingMode", Ptr, G, "int", 4)
    
    ; Use Drawing tools.
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", Clr, PtrA, pBrush)
    DllCall("gdiplus\GdipFillRectangle", Ptr, G, Ptr, pBrush, "float", 0, "float", 0, "float", cW, "float", cH)
    DllCall("gdiplus\GdipDeleteBrush", Ptr, pBrush)

    ; Update the layered window.
    DllCall("UpdateLayeredWindow", Ptr, hGdiLayer, Ptr, 0, Ptr, &Rect, "int64*", cW|cH<<32, Ptr, hdc, "int64*", 0, "uint", 0, "UInt*", 0x1FF0000, "uint", 2)

    ; Free Memory.
    DllCall("SelectObject", Ptr, hdc, Ptr, obm)
    DllCall("DeleteObject", Ptr, hbm)
    DllCall("DeleteDC", Ptr, hdc), DllCall("DeleteDC", Ptr, dc)
    DllCall("gdiplus\GdipDeleteGraphics", Ptr, G)
}

WM_MouseMove(wParam, lParam, msg, hWnd) {
    
    local i, mX, mY
    
    static handle, hwndGui, Higlight, ObjGuiMn, ObjCtrls, FocusRec := 0 ;, hWnd := Format("0x{1:x}", h)
    
    ObjGuiMn := {1: "ContextMenu", 2: "Apps"}, pGui1 := {1: "Destroy", 2: "-Disabled"}, pGui2 := {1: "+AlwaysOnTop", 2: "-Disabled"}
    ObjCtrls := {1: {1: "hGdiLayer", 2: hGdiLayer}, 2: {1: "hBtnApplistClose", 2: hBtnApplistClose, 3: "0x50E81123"}, 3: {1: "hBttnAddApp", 2: hBttnAddApp, 3: "0x40777777"}, 4: {1: "hBttnExit", 2: hBttnExit, 3: "0x40777777"}, 5: {1: "hBtnOk", 2: hBtnOk, 3: "0x40777777"}, 6: {1: "hBtnClose",  2: hBtnClose, 3: "0x50E81123"}}
    
    For i, v in [hDU, hDuUpFrq, hAppList] {
        if (hWnd = v) {
            hWndGui := v
    }   }

    if (hwnd = hMenuDel && !Higlight) {
        Higlight := 1
        Gui ContextMenu:font,  cffffff 
        GuiControl, Font, RemApp
    }
    else if (hWnd = hCntxMn && Higlight = 1) {
        Higlight := 0
        Gui ContextMenu:font, ce4e4c4
        GuiControl, Font, RemApp           
    }
    else if (hwnd = hCntxMn) {
        mX := lParam & 0xFFFF, mY := lParam >> 16
        i := ((mX < 2 || mX > 170) || (mY < 2 || mY > 22)), i ? (GuiUpdate(ObjGuiMn, pGui1, pGui2))
    }

    if (!GetKeyState("Lbutton", "D")) {
    
        for i, in ObjCtrls {
            if (hwnd = ObjCtrls[i, 2] && FocusRec = 0) {
                FocusRec := 1, CtrlID := ObjCtrls[i, 1], CtrlHwnd := ObjCtrls[i, 2], CrtlColor := ObjCtrls[i, 3]
                CreateFocusRec(CtrlHwnd, WinExist(), CrtlColor)

            }
            else if (hwnd = hwndGui && FocusRec = 1) {
               FocusRec := 0
               GuiUpdate({1: "GdiLayer"}, {1: "Destroy"}), FocusRec := 0
}   }   }   }

Wm_LbuttonDown(wParam, lParam, msg, hWnd) {
    ;Static hWnd := Format("0x{1:x}", h)
    
    if (hwnd = hGdiLayer) {
        GuiUpdate("GdiLayer", "Destroy")
        MouseGetPos, , , , hWnd, 2

        For k, v in Object("hBtnOk", "ButtonOke", "hBtnClose", "DuUpFrqClose", "hBtnApplistClose", "AppListClose"
                         , "hBttnAddApp", "AddApp", "hBttnExit", "AppListClose", "hMenuDel", "RemApp") {
            if (hWnd = %k%) {
                gosub % v
        } }
        Return
    }

    For k, v in Object("hDU", "DU_", "hDuUpFrq", "GuiUpFrq_", "hAppList", "Aplst_") {
        If (hwnd = %k%) {
            PostMessage, 0xA1, 2, , , % "ahk_id" %k%
            KeyWait, Lbutton
            
            WinGetPos, X, Y, , , % "ahk_id" %k%
            vX := v "X", %vX% := X, vY := v "Y", %vY% := Y
            IniWrite, % X, % A_ScriptDir "\Settings.ini", Coordinates, % vX
            IniWrite, % Y, % A_ScriptDir "\Settings.ini", Coordinates, % vY
}   }   }

ShellMessage(wParam, lParam:=0) {
    global

    Static CheckLease, DeviceState := 1
    
    ; HSHELL_WINDOWCREATED if wParam = 1
    ; ENables the nic when a application in Object Applist starts.
    ; Ghange menu lables from Enable to Disable.
    ; Enables DuMeter if it was switched on before. 
 
    if (wParam = 1 && WindowExist(Applist) && DeviceState = 0 || lParam = "StartUp") {
    
        EnableNet(), DeviceState := 1
        
        if (DuOn = 1 && !Running) {
            Running := 1
            
            if (DuMnLbl != "Disable DU Meter") {
            
                Gui, Show, % "x" Du_X "y" Du_Y "NA", DuOsd
                menu, DuMeter, rename,  % (DuMnLblNxt := "Enable DU Meter"), % (DuMnLbl := "Disable DU Meter")
                Settimer, UpdPerfdata, % UpdFrq
                ;gosub, UpdPerfdata
                
            } else {
            
                Gui, Show, % "x" Du_X "y" Du_Y "NA", DuOsd
                Settimer, UpdPerfdata, % UpdFrq
                ;gosub, UpdPerfdata
        } }
        
        ; A one time check to see if we still have the correct public ip address. 
        if (!CheckLease) {
            CheckLease := GetWanIp(DNSServer)
            if (CheckLease != WanIp) {
                Menu, tray, Tip, % (WanIp := CheckLease)
                IniWrite, % WanIp, % A_ScriptDir "\Settings.ini", Settings, WanIp
    }   }   }

    ; HSHELL_WINDOWDESTROYED if wParam = 2
    ; Disables the nic when last running application in Object Applist terminates and the device is On.
    ; Hide DuMeter gui since it's not needed.
    ; Changes menu lables accourding to nic status.
    
    if (wParam = 2 && !WindowExist(Applist) && DeviceState) {
        DisableNet(), Running := DeviceState := 0
        Gui, hide
        Settimer, UpdPerfdata, Off
}   }

Wm_MouseLeave(wParam, lParam, msg, h) {
    hWnd := Format("0x{1:x}", h)
    if (hwnd = hLv) {
        LV_Modify(RowNr, "-Select")
        ControlSend, , {tab}, ahk_id %hWnd%
}   }

TrayNotify(wParam, lParam) {
    if (lParam = 0x203 && !WinExist("Applist")) {
        Gosub, allowedApps  
    }
    else if (lParam = 0x203 && WinExist("Applist")) {
        Gosub, AppListClose
}   }


Menu, tray, Icon
Menu, tray, Icon, deskadp.dll, -100
;Menu, tray, Icon, pnidui.dll, 13

Global IconOpenDu, DuOn,hGdiLayer,IconEnabled,IconNoNetwork,LocalAreaNetwork,WanIp,ipv4,DNSServer,DeviceID,RowNr,RowTxT,MsgID,AutoToggle,ToggleOld,ToggleNew:=ToggleOff,ToggleOff:="Disable AutoToggle",ToggleOn:="Enable AutoToggle",UpdFrq:=1000,IconFile:="pnidui.dll",Applist:=[],Wmi:=ComObjGet("winmgmts:"),DuMnLbl := "Enable DU Meter",DuMnLblNxt := "Disable DU Meter"

UnitIn:="KB",UnitOut:="KB",Download:="0.00",Upload:="0.00",BIn:=BOut:=counter:=0,SldrPos:=1000,SS_CENTERIMAGE:=0x200,Modules:=LoadLibraries("Iphlpapi", "gdiplus"), DU_x := DU_y := Aplst_X := Aplst_Y := "Center"

ReadIni:
Loop, parse, % FileOpen(A_ScriptDir "\Settings.ini", 0).read(), `n, `r
{
	if (InStr(A_LoopField, "["))
		continue, ReadIni
	i := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1), %i% := SubStr(A_LoopField, InStr(A_LoopField, "=")+1)
}

; -------------------------- GuiContext/Tray-menu and GUI for D/U Meter -------------------------

Menu, tray, NoStandard
Menu, DuMeter, add, % DuMnLbl, DuMeter
Menu, DuMeter, add, Change Update Interval, GuiUpdateInt
Menu, DuMeter, add, Change Size, DuMeterScale
Menu, DuMeter, add
Menu, DuMeter, add, Double click tray opens DuMeter, TrayOpenDuMeter
Menu, DuMeter, Check, Double click tray opens DuMeter
Menu, DuMeter, UnCheck, Double click tray opens DuMeter

Menu, tray, add, DU Meter, :DuMeter
Menu, tray, add
Menu, tray, add, Configure AppList, allowedApps

Menu, tray, add, % (AutoToggle = 1 || AutoToggle = "") = 1 ? (ToggleNew := ToggleOff, AutoToggle := 1) : (ToggleNew := ToggleOn, AutoToggle = 0), ToggleAutoToggle
GuiControl +g, ToggleAutoToggle()

Menu, tray, add
Menu, tray, add, Network Connections, Connections
Menu, tray, add, Windows Firewall, Firewall
Menu, tray, add, Firewall Advanced, FirewallAdv
Menu, tray, add
Menu, tray, add, Restart script, Restart
Menu, tray, add, Exit, CloseScript

; Create Gui for D/U Meter.
DuSize <= 0 ? (s := "9", h := "28", w1 := "90", w2 := "52", w3 := "20") : (s := "10", h := "34", w1 := "103", w2 := "58", w3 := "25")
Gui, +LastFound +AlwaysOnTop +owner -Caption +Border HwndhDU
Gui, margin, 2, 2
Gui, font, s%s% w600 ce4e4c4 q5
Gui, color, 0x080808
Gui, add, Progress, xm ym h%h% w%w1% hWndhProgress +Background0x1f1f1f +0x8000000
Gui, add, text, xm+1 ym section BackgroundTrans, D:
Gui, add, text, xs BackgroundTrans, U:
Gui, add, text, ys w%w2% BackgroundTrans center section vBytesIn, %Download%
Gui, add, text, xs wp BackgroundTrans center vBytesOut, %Upload%
Gui, add, text, ys w%w3% BackgroundTrans section vUnitIn, %UnitIn%
Gui, add, text, xs wp BackgroundTrans vUnitOut, %UnitOut%
WinSet, Transparent, 180, ahk_id %hDU% 

If (!FileExist(A_ScriptDir "\Settings.ini")) {

	; Get icons for Win-10, Win-7 or Win-8.
	i := InStr(A_OSVersion, 10), i ? (IconDisabled := 1, IconEnabled := 13, IconNoNetwork := 14) : A_OSVersion = "Win_7" ? (IconDisabled:=26, IconEnabled := 28, IconNoNetwork := 29) : (IconDisabled := 2, IconEnabled:= 15, IconNoNetwork := 16), i:="", List := 1

    Gui GetDevices:Default
    Gui GetDevices:+LastFound +owner1 +owndialogs +AlwaysOnTop +LabelChooseDev -MinimizeBox -MaximizeBox
    Gui GetDevices:add, DropDownList, x12 y12 w345 h125 vList +AltSubmit Choose1
    
    EnumDev := ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_NetworkAdapter where PhysicalAdapter = true")._NewEnum()
    while EnumDev[i] {
        Name := i.Name, DeviceID := i.DeviceID, DeviceID%A_index% := DeviceID, NetworkCard%A_index% := Name
        if (Name) {
            GuiControl, , List, %Name%||
    }   }
    
    Gui GetDevices:add, Button, x367 y12 w96 h19 gChooseDevOk, Ok
    Gui GetDevices:show, , Choose a default network adapter
    Return

    ChooseDevClose:
    ChooseDevEscape:
    FileDelete, % A_ScriptDir "\Settings.ini"
    ExitApp
    
    ChooseDevOk:
    GuiUpdate("GetDevices", "Submit")
    GuiControl, +AltSubmit, List
    NetworkCard := NetworkCard%List%, DeviceID := DeviceID%List%
    IniWrite, %NetworkCard%, % A_ScriptDir "\Settings.ini", Settings, NetworkCard
    IniWrite, %DeviceID%, % A_ScriptDir "\Settings.ini", Settings, DeviceID
    
    GuiUpdate({1: "GetDevices", 2: "1"}, {1: "Destroy"}, {1: "Default"})
    
	for i, v in QueryNic() {
        IniWrite, % v, % A_ScriptDir "\Settings.ini", Settings, % i
        
        if (i = "ipv4" && InStr(v, "192.168")) {
            LocalAreaNetwork := 1
    }   }
    
	for i, v in ["LocalAreaNetwork", "IconDisabled", "IconEnabled", "IconNoNetwork"] {
        If (v) {
            IniWrite, % %v%, % A_ScriptDir "\Settings.ini", Settings, %v%
    }   }
    
	If (!FileExist(A_ScriptDir "\NetAccess.acc")) {
		for i, v in ["ahk_exe Firefox.exe","ahk_exe Iexplore.exe","ahk_exe Chrome.exe","ahk_exe MicrosoftEdge.exe"] {
            FileAppend, %v%`n, %A_ScriptDir%\NetAccess.acc
	}   }
    
    List:=i:=v:=EnumDevices:=""
    Gosub, RegHookAndMsgs
    Return
}

RegHookAndMsgs:
AppList := AHKGroupEX(), DllCall("RegisterShellHookWindow", UInt, A_ScriptHwnd)
MsgID := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")

AutoToggle < 1 ? (ToggleAutoToggle("1")) : ((WindowExist(AppList)) > 0 ? ShellMessage(1, "StartUp") : ShellMessage(2), OnMessage(MsgID,"ShellMessage"))

OnMessage(0x200, "Wm_MouseMove"), OnMessage(0x201, "Wm_LbuttonDown"), OnMessage(0x2A3, "Wm_MouseLeave"), OnMessage(0x404, "TrayNotify")
return

; Right click the DU window will show a context menu. The tray menu in this case.
GuiContextMenu:
menu, tray, show, % A_GuiX, % A_GuiY
return

; -------------------------------------------- Du Meter ------------------------------------------

; Show/Hide the D/U Meter Gui.
DuMeter:
if (DuMnLbl != "Disable DU Meter") {
	Gui, Show, % "x" DU_x "y" DU_y "NA", DuOsd
	menu, DuMeter, rename,  % DuMnLbl, % DuMnLblNxt
	DuMnLbl := "Disable DU Meter", DuMnLblNxt := "Enable DU Meter", Running := DuOn := 1
	Settimer, UpdPerfdata, % UpdFrq
	gosub, UpdPerfdata
} else {
	Settimer, UpdPerfdata, Off
	Gui hide
	menu, DuMeter, rename,  % DuMnLbl, % DuMnLblNxt
	DuMnLbl := "Enable DU Meter", DuMnLblNxt := "Disable DU Meter", PerfData := Running := DuOn := 0
}
IniWrite, % DuOn, % A_ScriptDir "\Settings.ini", Settings, DuOn
return

DuMeterScale:
IniWrite, % DuSize <= 0 ? (DuSize := 1) : (DuSize := 0), % A_ScriptDir "\Settings.ini", Settings, DuSize
Gosub, SkipSave
Return

TrayOpenDuMeter:
Return

; D/U Meter counter data.
UpdPerfdata:
if (GetKeyState("Lbutton", "D") && WinActive("ahk_id" hDu) || WinActive("ahk_id" hDuUpFrq) || WinActive("ahk_id" hAppList))
	return

if (Start && !End) {

    DllCall("QueryPerformanceCounter", "Int64*", End)
    BytesInOUt := GetNetSpeed(), BInEnd := BytesInOUt[1], BOutEnd := BytesInOUt[2]

    If (!CountDownActive)
        OldDownload := Download, OldUpload := Upload
 
    mls := ((End-Start)/Frq)/1000, Start := End := 0
    KBIn := ((BInEnd-BInStart)/1000)/(mls*0.9765625)
    KBOut :=((BOutEnd-BOutStart)/1000)/(mls*0.9765625)
    KBIn >= 1024 ? (Download := KBIn * 0.0009765625, UnitIn := "MB") : (Download := KBIn, UnitIn := "KB")
    KBOut >= 1024 ? (Upload := KBOut * 0.0009765625, UnitOut := "MB") : (Upload := KBOut, UnitOut := "KB")

    if (Download >= 1.00) {
    
        if (CountDownActive && Download > 2.00) {
            CountDownActive := NextPeriod := ""
        }
        else if (IdlPeriodOn) {
            IdlPeriodOn := NetworkTrafic := 0
            Settimer, UpdPerfdata, % UpdFrq
            ;Gosub, UpdPerfdata
        }
        
        if (!CountDownActive) {
            GuiControl(,,,{1: "BytesIn", 2: "BytesOut", 3: "UnitIn", 4: "UnitOut"}, {1: Round(Download, 2)}, {1: Round(Upload, 2)}, {1: UnitIn}, {1: UnitOut})
    }   }
    else if (Download < 1.00 ) {
            
        if (!IdlPeriodOn) {
            CountDownActive := 1
            GuiControl(,,,{1: "UnitIn", 2: "UnitOut"}, {1: UnitIn}, {1: UnitOut})
            A_TickCount >= NextPeriod ? (IdleTimer := 60000, NextPeriod := A_TickCount+IdleTimer) : (IdleTimer := NextPeriod-A_TickCount, GuiControl(,,,{1: "BytesIn", 2: "BytesOut"}, {1: OldDownload := Round(OldDownload - (Round(OldDownload/2, 2)), 2)}, {1: OldUpload := Round(OldUpload - (Round(OldUpload/2, 2)), 2)}))
            
            If (!NetworkTrafic) ; UnitIn := UnitOut := "KB",
                GuiControl(,,,{1: "BytesIn", 2: "BytesOut", 3: "UnitIn", 4: "UnitOut"}, {1: "0.00"}, {1: "0.00"}, {1: UnitIn}, {1: UnitOut}), NetworkTrafic := 1

            
            if ((IdleTimer//1000) <= 1 && CountDownActive) {
                GuiControl(,,,{1: "BytesIn", 2: "BytesOut"}, {1: "- - -"}, {1: "- - -"}), IdlPeriodOn := 1, IdleTimer := CountDownActive := 0
                SetTimer, UpdPerfdata, 5000
}   }   }   }

if (!Start) {
    DllCall("QueryPerformanceFrequency", "Int64*", Frq), DllCall("QueryPerformanceCounter", "Int64*", Start)
    BytesInOUt := GetNetSpeed(), BInStart := BytesInOUt[1], BOutStart := BytesInOUt[2], Frq //= 1000

}
return

GuiUpdateInt:
SldrPos := UpdFrq, TransClr := 0x222222 ; TransClr := 0x060606
WinSet, TransColor, %TransClr%, "UpdateInterval"

Gui DuUpFrq:+LastFound +hWndhDuUpFrq +AlwaysOnTop +owner1 -Caption +Border
Gui DuUpFrq:margin, 2, 2
Gui DuUpFrq:font, s8 w700 ce4e4c4 q5, lucon
Gui DuUpFrq:color, 0x262626
Gui DuUpFrq:Add, button, x-1 y-1 w0 h0 +Default vBtn1
Gui DuUpFrq:add, Progress, xm ym w458 h55 vBck hWndhProgress +Background0x141414 +0x8000000	
Gui DuUpFrq:Add, Text, x0 y0 w441 h15 vStr +%SS_CENTERIMAGE% +Center +TransColor +BackgroundTrans, % Str ; Info
Gui DuUpFrq:Add, Text, x+5 y1 w13  h13 Center gDuUpFrqClose hwndhBtnClose +TransColor +0x800200, X ; Button
Gui DuUpFrq:Add, Text, x17 y15 w35 h30 vBtnOk gButtonOke hwndhBtnOk -Transparent +TransColor +Center +0x800200, OK  ; Button
Gui DuUpFrq:add, slider, x60 yp h30 w399 vSldrPos gSldrEvents Range500-3000 Line50 +TickInterval500 +AltSubmit +hwndhSldr +Background +TabStop +E0x8 +0x800000, %UpdFrq%
Gui DuUpFrq:Show, h55 w460, UpdateInterval
WinSet, Transparent, 210, % "ahk_id" hDuUpFrq
Return

; Get chosen interval from slider.
SldrEvents:
Gui, submit, nohide
GuiControl, , Str, % SldrPos
UpdFrqOld := UpdFrq, SldrPosOld := SldrPos, UpdFrq := SldrPos
UpdFrqOld < UpdFrq ? (SldrMoved := UpdFrq-UpdFrqOld) : (SldrMoved := UpdFrqOld-UpdFrq)

if (A_GuiEvent < 8) {  
	for i, k in ["LEFT", "RIGHT", "UP", "DOWN", "WHEELUP", "WHEELDOWN", "PGUP", "PGDN", "HOME", "END"] {
		while (GetKeyState(k))	{
			KeyWait % %k%
			ControlFocus, ahk_class msctls_trackbar321
			ControlSend, ahk_class msctls_trackbar321, {Tab down}{Tab up}, ahk_id %hDuUpFrq%
			ControlFocus, ahk_class Static1
}   }  }
Gui, submit, nohide
return

ButtonOke:
Gui, Submit, NoHide:
IniWrite, %UpdFrq%, % A_ScriptDir "\Settings.ini", Settings, UpdFrq
Gui DuUpFrq:Destroy
Gui 1:-Disabled

If (DuOn = 1) {
	Settimer, UpdPerfdata, %UpdFrq%
	gosub, UpdPerfdata
}
return

DuUpFrqGuiEscape:
DuUpFrqClose:
GuiUpdate({1: "DuUpFrq", 2: "1"}, {1: "Destroy"}, {1: "-Disabled"})
return

; ------------------------------------- Gui to add/remove apps -------------------------------------

; ListView to config allowed applications
allowedApps:
if (WinExist("Applist")) {
	Gosub, AppListClose
    Return
}

        
ClipBrdOld := Clipboard, Clipboard := A_IconNumber
Menu, tray, Icon, deskadp.dll, -100

Gui Apps:Default
Gui Apps:+LastFound +AlwaysOnTop +owner1 -Caption +Border hWndhAppList 
Gui Apps:color, 0x080808
Gui Apps:font
Gui Apps:font, s9 w600 ce4e4c4 q5, Lucida Console
Gui Apps:add, Picture, xm ym h16 w16 +AltSubmit icon1, deskadp.dll
Gui Apps:add, Text, x+m, Applist
Gui Apps:add, Text, x+153 y5 w13  h13 gAppListClose hWndhBtnApplistClose +0x800200 Center, X ; Button
Gui Apps:add, ListView, x13 y40 w240 h190 Section +Background0x202020 gLVSubroutine vAppList hWndhLv -hdr, AppList

For i, App in Applist
	LvSize := LV_Add("", SubStr(App, 9)), i := "" 
GuiControl +AltSubmit, AppList

Gui Apps:add, Text, xs w115 h20 +Section hWndhBttnAddApp vBttn gAddApp +0x200 +border Center, Add App ; Button
Gui Apps:add, Text, ys wp hp hWndhBttnExit gAppListClose +0x200 +border Center, Exit ; Button
Gui Apps:Show, x%Aplst_X% y%Aplst_Y% w266 h269, Applist
WinSet, Transparent, 220, % "ahk_id " hAppList
;WinSet, TransColor, 0x6e6e6e 200
Menu, tray, Icon, % IconFile, % Clipboard
Clipboard := ClipBrdOld, ClipBrdOld := ""
return
   
LVSubroutine:
Gui, Submit, NoHide

if (A_guiEvent = "RightClick") { ; && A_EventInfo >= 1) {
	RowNr := A_EventInfo
	LV_GetText(RowTxT, A_EventInfo)
	s := StrLen(" Delete: " RowTxT)*8.5
	if (RowTxT != "" && RowTxT != "AppList") {
		CoordMode, Mouse, Screen
		Gui Apps:+Disabled
		Gui ContextMenu:Default
        Gui ContextMenu:+LastFound +AlwaysOnTop +owner1 -Caption HwndhCntxMn
		Gui ContextMenu:margin, 1, 1
        Gui ContextMenu:font, s9 w600 ce4e4c4 q5, Lucida Console ;, Sitka Small
		Gui ContextMenu:color, 0x080808
		Gui ContextMenu:add, text, xm+10 ym+2 h20 w%s% +section +0x200 vRemApp gRemApp HwndhMenuDel, % " Delete: " RowTxT
		MouseGetPos, mX, mY
		Gui ContextMenu:show, % "x" mX-5 "y" mY-5 "w" s+20 "h" 26, ContextMenu
		WinSet, Transparent, 230, % "ahk_id " hCntxMn
}   }

LV_Modify(A_EventInfo, "-Select")
ControlSend, , {tab}, ahk_id %hLv%
Gui, Submit, NoHide
return

; Add new app to the list.
AddApp:
GuiUpdate("Apps", "hide")
FileSelectFile, App, M3, C:\, ,*.exe
GuiUpdate("Apps", "Default", "Show", "Submit", "+AlwaysOnTop")

Loop, parse, App, `n
{
	if (A_Index >= 2) {
		AppList := AHKGroupEX(0, A_LoopField)
		LV_Add((LvSize+=1), SubStr(AppList[LvSize], 9))
}   }

return

; Delete app from list.
RemApp:
GuiUpdate({1: "GdiLayer", 2: "ContextMenu", 3: "Apps"}, {1: "Destroy"}, {1: "Destroy"}, {1: "-Disabled", 2: "Default", 3: "+AlwaysOnTop"})

LV_Delete(RowNr), Applist := AHKGroupEX(RowNr), LvSize -= 1

if (FileExist("NetAccess.acc"))
	FileDelete, NetAccess.acc
 
For i, App in Applist
	FileAppend, %App%`n, %A_ScriptDir%\NetAccess.acc
	
GuiUpdate("Apps", "Submit")
return

AppsGuiEscape:
AppListClose:
GuiUpdate({1: "Apps", 2: "1"}, {1: "-Disabled", 2: "Default", 3: "Submit", 4: "Destroy"}, {1: "Default"})
return

; --------------------------------- Launch windows console applets ---------------------------------

; Start Control Panel\Network and Internet\Network Connections.
Connections:
Run % A_WinDir "\explorer.exe shell:::{26EE0668-A00A-44D7-9371-BEB064C98683}\0\::{7007ACC7-3202-11D1-AAD2-00805FC1270E}"
return

; Start Control Panel\All Control Panel Items\Windows Defender Firewall.
Firewall:
Run % A_WinDir "\explorer.exe shell:::{26EE0668-A00A-44D7-9371-BEB064C98683}\0\::{4026492F-2F69-46B8-B9BF-5654FC07E423}"
return

; Start Windows firewall mmc snapin
FirewallAdv:    
Run % A_WinDir "\system32\wf.msc"
return
 
; --------------------------------------- End script session ---------------------------------------

; Start a new instance.
Restart:
SetTitleMatchMode, 1

if ((hwnd := WinExist("AutoGUI ")) && A_ThisLabel != "DuMeterScale") {
    if (hwnd != WinActive())
        WinActivate, ahk_id %hwnd%
    Send ^s
}

SkipSave:

if (A_IsCompiled) {
	Run *RunAs "%A_ScriptFullPath%" /restart
} else {
	Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
}

; Close script instance.
~Esc & Alt::
Exit:
CloseScript:
FreeLibraries(Modules)
ExitApp


