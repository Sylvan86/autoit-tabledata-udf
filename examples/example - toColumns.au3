#include "../TableData.au3"
#include <WinAPIConv.au3>


#region example _td_toColumns
; Read data from command (return csv-data):
Global $sTaskListRaw = _getCmdOutput('tasklist /FO CSV')

; Transfer data to table type:
Global $mData =  _td_fromCsv($sTaskListRaw, ',', "1-3", "process|pid|session|nr|mem")

; convert into map of columns
$mData = _td_toColumns($mData)

; handle the process list
Global $aProcesses = $mData.process
$aProcesses = _ArrayUnique($aProcesses,0,0,0,0)
_ArraySort($aProcesses)

; display process list
_ArrayDisplay($aProcesses, "process list", "", 64)
#EndRegion



#Region helper functions
; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $STDIN_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc

