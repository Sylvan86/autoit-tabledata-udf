#include "../TableData.au3"
#include <WinAPIConv.au3>


#Region example 1 - _td_TableToMaps
; Read data from command (return csv-data):
Global $sTaskListRaw = _getCmdOutput('tasklist /FO CSV',  True)

; Transfer data to table type:
Global $mData =  _td_fromCsv($sTaskListRaw, ',', "1-3", "name|pid|session|nr|mem")

; handle the datasets like objects:
Global $aProcesses = _td_TableToMaps($mData)
For $mP in $aProcesses
	ConsoleWrite( $mP.name &  " [" & $mP.pid & "]: " & $mP.mem & @CRLF)
Next
#EndRegion


#Region example 2 - _td_MapsToTable (backwards)

Global $mTable = _td_MapsToTable($aProcesses)
_td_display($mTable, "rebuild table")

#EndRegion




#Region helper function
; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $STDIN_CHILD + $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc
#EndRegion