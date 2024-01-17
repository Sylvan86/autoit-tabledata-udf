#include "../TableData.au3"
#include <WinAPIConv.au3>

; #description# =================================================================================================================
; examples for using the _td_fromFixWidth() function
; ===============================================================================================================================


#Region example 1 - netstat simple
; Read data from command:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')

; Transfer data to table type:
Global $mData = _td_fromString($sNetStatRaw, "", "", "1-4", "protocol|local|remote|status|PID")

; display data:
_td_display($mData, "example 1 - netstat simple")
#EndRegion


#Region example 2 - netstat with column processing
; Read data from command:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')

; Transfer data to table type with special handling of columns:
Global $mData = _td_fromString($sNetStatRaw, "", "", "1-4", "protocol|local|remote|status|PID", ";StringRegExp($x, '(.+):([^:\v]*)$', 3);StringRegExp($x, '(.+):([^:\v]*)$', 3)")

; display data:
_td_display($mData, "example 2 - netstat with column processing")
#EndRegion




#Region help functions
; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $STDIN_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc


; example user function to show how to split values into multiple columns
Func _splitIPPort($sString)
	Return StringRegExp($sString, '(.+):([^:\v]*)$', 3)
EndFunc
#EndRegion





