#include "../TableData.au3"
#include <WinAPIConv.au3>



#Region example
; Read data into table object:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')
; Transfer data to table type with special handling of columns:
Global $mData = _td_fromString($sNetStatRaw, "", "", "1-4", "protocol|local|remote|status|PID", ";StringRegExp($x, '(.+):([^:\v]*)$', 3);StringRegExp($x, '(.+):([^:\v]*)$', 3)")


; convert data into a csv string:
$sCSV = _td_toCsv($mData)

; print out csv-data
ConsoleWrite($sCSV)
#EndRegion



#Region help functions
; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $STDIN_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc
#EndRegion