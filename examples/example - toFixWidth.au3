#include "../TableData.au3"
#include <WinAPIConv.au3>



#Region example table to fixed width columns string
; Read data into table object:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')
; Transfer data to table type with special handling of columns:
Global $mData = _td_fromString($sNetStatRaw, "", "", "1-4", "protocol|local|remote|status|PID", ";StringRegExp($x, '(.+):([^:\v]*)$', 3);StringRegExp($x, '(.+):([^:\v]*)$', 3)")

; convert data into a fixed-width table string:
$sFixWidths = _td_toFixWidth($mData)

; print out string table
ConsoleWrite($sFixWidths)
#EndRegion


#Region example table to fixed width columns string with user defined width for the first 2 columns and a header sep
; Read data into table object:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')
; Transfer data to table type with special handling of columns:
Global $mData = _td_fromString($sNetStatRaw, "", "", "1-4", "protocol|local|remote|status|PID", ";StringRegExp($x, '(.+):([^:\v]*)$', 3);StringRegExp($x, '(.+):([^:\v]*)$', 3)")

; convert data into a fixed width table string with user defined width for the first 2 columns and add a header sep:
$sFixWidths = _td_toFixWidth($mData, "15|25", True, " ", False, @CRLF, "=")

; print out string table
ConsoleWrite($sFixWidths)
#EndRegion




#Region help functions
; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $STDIN_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc
#EndRegion