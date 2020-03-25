;=============================================================================================================================================
; File location:
;  C:\Windows\ShellNew\Template.ahk         BACKUP YOU'RE ORIGINAL FILE!
;=============================================================================================================================================
#NoEnv                                      ; Do not use the environmental variables used by you're operatingsystem.
#SingleInstance force                       ; Replace old with new instance if script is run twice. [Ignore = Keep Current | Off = Run all]
#Include %A_MyDocuments%\AutoHotkey\Lib     ; Includes the default user library and use all functions. Function libraries need be added later.
#KeyHistory 0                               ; Improve performance. Key history is not recorded.
Listlines off                               ; Improve performance. Line history is not recorded. [Off | On = default]
SetBatchLines -1                            ; Improve performance. Do not sleep 10ms between line execution. Fast but may cause failures.
SendMode Event                              ; Send will act as SendEvent. Slower but more reliable. [Input | Play | Event | InputThenPlay]
SetKeyDelay 50, 10                          ; Pause 50ms between sending key's. Default is 10. Not used if SendMode is Input.
SetTitleMatchMode 2                         ; Matches you're string anywhere within the title. [1 = Must start with | 3 = Exact Match | RegEx]
SetWorkingDir %A_ScriptDir%                 ; Set 'working directory' to the file location of the script.
;=============================================================================================================================================
; position controls according to the font size used by you're GUI. When font size increases, controls will position correctly inside the GUI.
; Use AutoXYWH.ahk function to handle resizeing. http://ahkscript.org/boards/viewtopic.php?t=1079
;=============================================================================================================================================
FS  := 8                           		    ; Default font size. In windows Margins are defined by the hight of a font used by the GUI.
Xm	:= Round(FS*1.25)        			        ; Width margin (X), 1.25 times font size. Left to right.
Ym 	:= Round(FS*0.75)        			        ; Hight margin (Y), 0.75 times font size. Top to bottom. e.g. Gui, add, text, X%Xm% Y%Ym%
;=============================================================================================================================================


