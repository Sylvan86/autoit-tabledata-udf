#include "../TableData.au3"
#include <WinAPIConv.au3>


#region example 1 - simple join (inner join as default) by same column name

; get data from netstat
Global $mNetStat = _td_fromFixWidth(_getCmdOutput('netstat -ano'), "7;23;23;16;Number 100", "1-2", true)
; get data from tasklist
Global $mTaskList =  _td_fromCsv(_getCmdOutput('tasklist /FO CSV',  True), ',', 0, True)

; show data
_td_display($mNetStat, "netstat data")
_td_display($mTaskList, "tasklist data")

; link the NetStat data with the data for the associated process
$mJoined = _td_join($mNetStat, $mTaskList, "PID")

; display the combined table object
_td_display($mJoined, "example 1 - Joined tables: open ports and their corresponding process info")

#EndRegion


#region example 2 - (left) join with special column treatment (here: convert PID string to number)

; get data from netstat
Global $mNetStat = _td_fromFixWidth(_getCmdOutput('netstat -ano'), "7;23;23;16;", "1-2", true)
; get data from tasklist
Global $mTaskList =  _td_fromCsv(_getCmdOutput('tasklist /FO CSV',  True), ',', 0, True)

; show data
_td_display($mNetStat, "netstat data")
_td_display($mTaskList, "tasklist data")

; link the NetStat data with the data for the associated process
$mJoined = _td_join($mNetStat, $mTaskList, "Number($A.PID)", "PID", "left", False)

; display the combined table object
_td_display($mJoined, "example 2 - Joined tables: open ports and their corresponding process info")

#EndRegion



; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False, $oFlags = $STDOUT_CHILD)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $oFlags)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc