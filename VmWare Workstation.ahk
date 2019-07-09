#NoEnv
#NoTrayIcon
#SingleInstance off
DetectHiddenWindows on
SetTitleMatchMode 2

if (A_IsAdmin && (State := A_Args[1])) {
    Error := State = "/Start" ? StartServices() : StopServices()
    if (Error) {
        MsgBox,,COM Error!, % "Error message:`n  " Error "`n`nThe script will now exit!"
        Process, Close, % A_Args[2]
    }
    ExitApp
}

Global Executable   := "vmware.exe"
Path                := "C:\Program Files (x86)\VMware\VMware Workstation\"
ExecPath            := Path Executable

; When VmWare is not running.
; Then the script will here initiate the start of vmware, it's virtual adapters and services.
If (!WinExist("ahk_exe" Executable)) {
    Services("Start")
    run %ExecPath%, %Path%
    WinWait ahk_exe %Executable%
}

; Create shell message hook for the OnAppExit() monitor function.
DllCall("RegisterShellHookWindow", UInt, A_ScriptHwnd)
MessageID := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")
OnMessage(MessageID, "OnAppExit")
Return

; Each application closed by the user will here be checked if it is Vmware.exe.
; When Vmware.exe terminates, the related services and Virtual adapters will also shutdown.
OnAppExit(wParam, lParam) {
    static AppClose := 2  
    if (wParam = AppClose && !WinExist("ahk_exe " Executable)) {
	    Services("Stop")
        ExitApp
}}

; Run a second instance of this script with administrative privileges.
; This is needed for handeling stopping and starting of services.
; Variable State should eighter contain the word "Stop" or "Start".
; Variable Pid will hold the proccess ID of the current running instance.
Services(State) {
    Pid := DllCall("GetCurrentProcessId")

    If (State = "Start") {
        RunWait *RunAs "%A_AhkPath%"  /ErrorStdOut "%A_ScriptFullPath%" /Start %Pid%
    } Else If (State = "Stop") {
        RunWait *RunAs "%A_AhkPath%" /ErrorStdOut "%A_ScriptFullPath%" /Stop %Pid%
}}

; -------------- These functions below execute with administative previlages --------------

; StartServices() like the name suggests. Will start services related to VMware. 
; It will also enable all virtual networkdevices related to VMware and change the startup mode
; for each services to manual. This means that after running this script VMware can not properly
; start by running Vmware.exe. Unless you manually enable everthing that's changed.
StartServices() {
    ServicesKey             := "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services"
    WMIServices             := ComObjGet("winmgmts:")
    Win32_NetworkAdapter    := WMIServices.ExecQuery("SELECT * FROM Win32_NetworkAdapter")._NewEnum()

    ; Find and enable all VmWare virtual network adapters.
    ; The script will assume that all found adapters will be enabled.
    while Win32_NetworkAdapter[Value] {
        If (Value.ServiceName = "VMnetAdapter")
            WMIServices.ExecMethod("Win32_NetworkAdapter.DeviceID='" Value.DeviceID "'","Enable")
    }
    
    ; Try to enable the services listed in the object below. The startup order is structured according to there dependencies.
    Try {
            for i, VmServices in ["VMnetDHCP", "VMware NAT Service", "VMAuthdService", "VMUSBArbService", "VMwareHostd"] 
            {   
                ; Start the current services.
                WMIServices.ExecMethod("Win32_Service.Name='" VmServices "'","StartService")
           
                WaitStartReady:
                ; Retrieves info about the selected services.
                for Services in WMIServices.ExecQuery("SELECT * FROM Win32_Service where Name = '" VmServices "'") {
                    ; Check to see if the services is finished with loading.
                    ; And if it's status is not running, wait 1/10 of a second. Then check again.
                    if (Services.State != "Running") {
                        Sleep 100
                        Continue, WaitStartReady
                    }
                    ; Change the startup mode of each services to manual when it is something other than that.
                    ; RegWrite one will set the startupmode to manual/demand startup.
                    ; RegWrite two prevents error control from re-enabling the services.
                    if (Services.StartMode != "Manual"){
                        RegWrite, REG_DWORD, %ServicesKey%\%VmServices%, Start, 3
                        RegWrite, REG_DWORD, %ServicesKey%\%VmServices%, FailureActions, 0

        ; Any COM error will be catched here and formated for proper reading (doesn't mean they allway's make sense). 
    }}}} Catch {
        Return FormatMessage(A_LastError)
    }
    Return
}

; StopServices() is called when the script "sees" that vmware is exiting.
; It will accordingly shutdown all releated services and networkadapters.
StopServices() {
    WMIServices:=ComObjGet("winmgmts:")
    Win32_NetworkAdapter := WMIServices.ExecQuery("SELECT * FROM Win32_NetworkAdapter")._NewEnum()
    
    while Win32_NetworkAdapter[Value] {
        If (Value.ServiceName = "VMnetAdapter")
            WMIServices.ExecMethod("Win32_NetworkAdapter.DeviceID='" Value.DeviceID "'","Disable")
    }
    
    Try {
            for i, VmServices in ["VMwareHostd", "VMUSBArbService", "VMAuthdService", "VMware NAT Service", "VMnetDHCP"] 
            {
                WMIServices.ExecMethod("Win32_Service.Name='" VmServices "'","StopService")
                
                WaitStopReady:
                for Services in WMIServices.ExecQuery("SELECT * FROM Win32_Service where Name = '" VmServices "'") {
                    if (Services.State = "Running") {
                        Sleep 100
                        Continue, WaitStopReady
    }}}} Catch {
        Return FormatMessage(A_LastError)
    }
    Return
}

; Basicly it retrieves a readable string from the message buffer.
FormatMessage(MsgID) {
    static  Size := VarSetCapacity(Msgbuf, 65536)
    ,       FORMAT_MESSAGE_FROM_SYSTEM := 0x00001000
    ,       LANG_SYSTEM_DEFAULT := 0x0800
    ;        Optional constants
    ,       FORMAT_MESSAGE_ALLOCATE_BUFFER := 0x00000100
    ,       FORMAT_MESSAGE_ARGUMENT_ARRAY := 0x00002000
    ,       FORMAT_MESSAGE_IGNORE_INSERTS := 0x00000200
    ,       FORMAT_MESSAGE_MAX_WIDTH_MASK := 0x000000FF
    ,       FORMAT_MESSAGE_FROM_HMODULE := 0x00000800
    ,       FORMAT_MESSAGE_FROM_STRING := 0x00000400
    ,       LANG_USER_DEFAULT := 0x0400
        
    if !(DllCall("FormatMessage", "UInt", FORMAT_MESSAGE_FROM_SYSTEM, "Ptr", 0, "UInt", MsgID, "UInt", LANG_SYSTEM_DEFAULT, "Ptr", &Msgbuf, "UInt", Size, "UInt*", 0))
        return DllCall("GetLastError")
    return StrGet(&Msgbuf)
}
; --------------------------------------------------------------------------------------------------------------------------

/*
Window:
Process name: ahk_exe vmware-unity-helper.exe
Window Class: ahk_class ATL:00A5E140

Control
&1 Windows 10 x64
ahk_class Button1


dwFlags
FORMAT_MESSAGE_ALLOCATE_BUFFER := 0x00000100
FORMAT_MESSAGE_ARGUMENT_ARRAY := 0x00002000
FORMAT_MESSAGE_FROM_SYSTEM := 0x00001000
FORMAT_MESSAGE_IGNORE_INSERTS := 0x00000200
FORMAT_MESSAGE_MAX_WIDTH_MASK := 0x000000FF
FORMAT_MESSAGE_FROM_HMODULE := 0x00000800
FORMAT_MESSAGE_FROM_STRING := 0x00000400


dwLanguageId
LANG_SYSTEM_DEFAULT := 0x0800
LANG_USER_DEFAULT := 0x0400

============================================================FormatMessage============================================================================
https://docs.microsoft.com/en-us/windows/desktop/api/winbase/nf-winbase-formatmessage#parameters

C++ Code:

DWORD FormatMessage(
  DWORD   dwFlags,
  LPCVOID lpSource,
  DWORD   dwMessageId,
  DWORD   dwLanguageId,
  LPTSTR  lpBuffer,
  DWORD   nSize,
  va_list *Arguments
);


dwFlags
The formatting options, and how to interpret the lpSource parameter.
The low-order byte of dwFlags specifies how the function handles line breaks in the output buffer.
The low-order byte can also specify the maximum width of a formatted output line.

This parameter can be one or more of the following values.

FORMAT_MESSAGE_ALLOCATE_BUFFER
0x00000100

	The function allocates a buffer large enough to hold the formatted message, and places a pointer to the allocated buffer at the address specified by lpBuffer.
    The lpBuffer parameter is a pointer to an LPTSTR; you must cast the pointer to an LPTSTR (for example, (LPTSTR)&lpBuffer).
    The nSize parameter specifies the minimum number of TCHARs to allocate for an output message buffer.
    The caller should use the LocalFree function to free the buffer when it is no longer needed.
	If the length of the formatted message exceeds 128K bytes, then FormatMessage will fail and a subsequent call to GetLastError will return ERROR_MORE_DATA.
	In previous versions of Windows, this value was not available for use when compiling Windows Store apps.
    As of Windows 10 this value can be used.
	Windows Server 2003 and Windows XP:  
	If the length of the formatted message exceeds 128K bytes, then FormatMessage will not automatically fail with an error of ERROR_MORE_DATA.
	Windows 10:   LocalAlloc() has different options: LMEM_FIXED, and LMEM_MOVABLE.
    FormatMessage() uses LMEM_FIXED, so HeapFree can be used.
    If LMEM_MOVABLE is used, HeapFree cannot be used.

FORMAT_MESSAGE_ARGUMENT_ARRAY
0x00002000

	The Arguments parameter is not a va_list structure, but is a pointer to an array of values that represent the arguments.
	This flag cannot be used with 64-bit integer values. If you are using a 64-bit integer, you must use the va_list structure.

FORMAT_MESSAGE_FROM_HMODULE
0x00000800

	The lpSource parameter is a module handle containing the message-table resource(s) to search.
    If this lpSource handle is NULL, the current process's application image file will be searched.
    This flag cannot be used with FORMAT_MESSAGE_FROM_STRING.
	If the module has no message table resource, the function fails with ERROR_RESOURCE_TYPE_NOT_FOUND.

FORMAT_MESSAGE_FROM_STRING
0x00000400

    The lpSource parameter is a pointer to a null-terminated string that contains a message definition.
    The message definition may contain insert sequences, just as the message text in a message table resource may.
    This flag cannot be used with FORMAT_MESSAGE_FROM_HMODULE or FORMAT_MESSAGE_FROM_SYSTEM.

FORMAT_MESSAGE_FROM_SYSTEM
0x00001000

	The function should search the system message-table resource(s) for the requested message.
    If this flag is specified with FORMAT_MESSAGE_FROM_HMODULE, the function searches the system message table if the message is not found in the module specified by lpSource.
    This flag cannot be used with FORMAT_MESSAGE_FROM_STRING.
	If this flag is specified, an application can pass the result of the GetLastError function to retrieve the message text for a system-defined error.

FORMAT_MESSAGE_IGNORE_INSERTS
0x00000200

	Insert sequences in the message definition are to be ignored and passed through to the output buffer unchanged.
    This flag is useful for fetching a message for later formatting.
    If this flag is set, the Arguments parameter is ignored.

 

The low-order byte of dwFlags can specify the maximum width of a formatted output line.
The following are possible values of the low-order byte.

0
	There are no output line width restrictions.
    The function stores line breaks that are in the message definition text into the output buffer.


FORMAT_MESSAGE_MAX_WIDTH_MASK
0x000000FF

	The function ignores regular line breaks in the message definition text.
    The function stores hard-coded line breaks in the message definition text into the output buffer.
    The function generates no new line breaks.
	If the low-order byte is a nonzero value other than FORMAT_MESSAGE_MAX_WIDTH_MASK, it specifies the maximum number of characters in an output line.
    The function ignores regular line breaks in the message definition text.
    The function never splits a string delimited by white space across a line break.
    The function stores hard-coded line breaks in the message definition text into the output buffer.
    Hard-coded line breaks are coded with the %n escape sequence.
	
    lpSource
	The location of the message definition.
    The type of this parameter depends upon the settings in the dwFlags parameter.

    dwFlags
    FORMAT_MESSAGE_FROM_HMODULE
    0x00000800

        A handle to the module that contains the message table to search.

    FORMAT_MESSAGE_FROM_STRING
    0x00000400

        Pointer to a string that consists of unformatted message text.
        It will be scanned for inserts and formatted accordingly.


If neither of these flags is set in dwFlags, then lpSource is ignored.

dwMessageId
The message identifier for the requested message.
This parameter is ignored if dwFlags includes FORMAT_MESSAGE_FROM_STRING.

dwLanguageId
The language identifier for the requested message.
This parameter is ignored if dwFlags includes FORMAT_MESSAGE_FROM_STRING.
If you pass a specific LANGID in this parameter, FormatMessage will return a message for that LANGID only.
If the function cannot find a message for that LANGID, it sets Last-Error to ERROR_RESOURCE_LANG_NOT_FOUND.
If you pass in zero, FormatMessage looks for a message for LANGIDs in the following order:

1. Language neutral
2. Thread LANGID, based on the thread's locale value
3. User default LANGID, based on the user's default locale value
4. System default LANGID, based on the system default locale value
5. US English

If FormatMessage does not locate a message for any of the preceding LANGIDs, it returns any language message string that is present.
If that fails, it returns ERROR_RESOURCE_LANG_NOT_FOUND.

lpBuffer
A pointer to a buffer that receives the null-terminated string that specifies the formatted message.
If dwFlags includes FORMAT_MESSAGE_ALLOCATE_BUFFER, the function allocates a buffer using the LocalAlloc function, and places the pointer to the buffer at the address specified in lpBuffer.

This buffer cannot be larger than 64K bytes.

nSize
If the FORMAT_MESSAGE_ALLOCATE_BUFFER flag is not set, this parameter specifies the size of the output buffer, in TCHARs.
If FORMAT_MESSAGE_ALLOCATE_BUFFER is set, this parameter specifies the minimum number of TCHARs to allocate for an output buffer.

The output buffer cannot be larger than 64K bytes.

Arguments
An array of values that are used as insert values in the formatted message. A %1 in the format string indicates the first value in the Arguments array; a %2 indicates the second argument; and so on.
The interpretation of each value depends on the formatting information associated with the insert in the message definition. The default is to treat each value as a pointer to a null-terminated string.
By default, the Arguments parameter is of type va_list*, which is a language- and implementation-specific data type for describing a variable number of arguments. The state of the va_list argument is undefined upon return from the function. To use the va_list again, destroy the variable argument list pointer using va_end and reinitialize it with va_start.
If you do not have a pointer of type va_list*, then specify the FORMAT_MESSAGE_ARGUMENT_ARRAY flag and pass a pointer to an array of DWORD_PTR values; those values are input to the message formatted as the insert values. Each insert must have a corresponding element in the array.

Return Value
If the function succeeds, the return value is the number of TCHARs stored in the output buffer, excluding the terminating null character.
If the function fails, the return value is zero. To get extended error information, call GetLastError.

Remarks
Within the message text, several escape sequences are supported for dynamically formatting the message. These escape sequences and their meanings are shown in the following tables. All escape sequences start with the percent character (%).
Escape sequence 	Meaning
%0 	Terminates a message text line without a trailing new line character. This escape sequence can be used to build up long lines or to terminate the message itself without a trailing new line character. It is useful for prompt messages.
%n!format string! 	Identifies an insert. The value of n can be in the range from 1 through 99. The format string (which must be surrounded by exclamation marks) is optional and defaults to !s! if not specified. For more information, see Format Specification Fields.

The format string can include a width and precision specifier for strings and a width specifier for integers.
Use an asterisk () to specify the width and precision.
For example, %1!.*s! or %1!*u!.

If you do not use the width and precision specifiers, the insert numbers correspond directly to the input arguments.
For example, if the source string is "%1 %2 %1" and the input arguments are "Bill" and "Bob", the formatted output string is "Bill Bob Bill".

However, if you use a width and precision specifier, the insert numbers do not correspond directly to the input arguments.
For example, the insert numbers for the previous example could change to "%1!*.*s! %4 %5!*s!".

The insert numbers depend on whether you use an arguments array (FORMAT_MESSAGE_ARGUMENT_ARRAY) or a va_list.
For an arguments array, the next insert number is n+2 if the previous format string contained one asterisk and is n+3 if two asterisks were specified.
For a va_list, the next insert number is n+1 if the previous format string contained one asterisk and is n+2 if two asterisks were specified.

If you want to repeat "Bill", as in the previous example, the arguments must include "Bill" twice.
For example, if the source string is "%1!*.*s! %4 %5!*s!", the arguments could be, 4, 2, Bill, Bob, 6, Bill (if using the FORMAT_MESSAGE_ARGUMENT_ARRAY flag).
The formatted string would then be "  Bi Bob   Bill".

Repeating insert numbers when the source string contains width and precision specifiers may not yield the intended results.
If you replaced %5 with %1, the function would try to print a string at address 6 (likely resulting in an access violation).

Floating-point format specifiers—e, E, f, and g—are not supported.
The workaround is to use the StringCchPrintf function to format the floating-point number into a temporary buffer, then use that buffer as the insert string.

Inserts that use the I64 prefix are treated as two 32-bit arguments.
They must be used before subsequent arguments are used.
Note that it may be easier for you to use StringCchPrintf instead of this prefix.
 

Any other nondigit character following a percent character is formatted in the output message without the percent character.

Following are some examples.

Format string 	Resulting output
----------------------------------
%% 	            A single percent sign.
%space 	        A single space. This format string can be used to ensure the appropriate number of trailing spaces in a message text line.
%. 	            A single period. This format string can be used to include a single period at the beginning of a line without terminating the message text definition.
%! 	            A single exclamation point. This format string can be used to include an exclamation point immediately after an insert without its being mistaken for the beginning of a format string.
%n 	            A hard line break when the format string occurs at the end of a line. This format string is useful when FormatMessage is supplying regular line breaks so the message fits in a certain width.
%r 	            A hard carriage return without a trailing newline character.
%t 	            A single tab.
 
Security Remarks
If this function is called without FORMAT_MESSAGE_IGNORE_INSERTS, the Arguments parameter must contain enough parameters to satisfy all insertion sequences in the message string, and they must be of the correct type.
Therefore, do not use untrusted or unknown message strings with inserts enabled because they can contain more insertion sequences than Arguments provides, or those that may be of the wrong type.
In particular, it is unsafe to take an arbitrary system error code returned from an API and use FORMAT_MESSAGE_FROM_SYSTEM without FORMAT_MESSAGE_IGNORE_INSERTS.

