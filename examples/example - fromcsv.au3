#include "../TableData.au3"
#include <WinAPIConv.au3>


; #description# =================================================================================================================
; examples for using the _td_fromCsv() function
; ===============================================================================================================================


#Region example 1 - tasklist
; Read data from command (return csv-data):
Global $sTaskListRaw = _getCmdOutput('tasklist /FO CSV',  True)

; Transfer data to table type:
Global $mData =  _td_fromCsv($sTaskListRaw, ',', "2", True)

; display data
_td_display($mData, "example 1 - tasklist")
#EndRegion


#Region example 2 - driverquery
; Read data from command (return csv-data):
Global $sTaskListRaw = _getCmdOutput('driverquery /FO CSV',  True)

; Transfer data to table type with treatment of a column (separation of date and time in separate columns):
Global $mData =  _td_fromCsv($sTaskListRaw, ',', "", True, ";;;StringSplit($x,' ',3)")

; display data
_td_display($mData, "example 2 - driverquery")
#EndRegion





#Region helper function
; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $STDIN_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc
#EndRegion

