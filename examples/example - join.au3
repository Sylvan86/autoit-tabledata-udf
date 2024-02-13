#include "../TableData.au3"
#include <WinAPIConv.au3>

; get data from netstat
Global $mNetStat = _td_fromFixWidth(_getCmdOutput('netstat -ano'), "7;23;23;16;Number 100", "1-2", true)
; get data from tasklist
Global $mTaskList =  _td_fromCsv(_getCmdOutput('tasklist /FO CSV',  True), ',', "2", True)

; show data
_td_display($mNetStat, "netstat data")
_td_display($mTaskList, "tasklist data")

; link the NetStat data with the data for the associated process
$mJoined = _td_join($mNetStat, $mTaskList, "PID", "PID", "left")
_td_display($mJoined, "Joined tables: open ports and their corresponding process info")



; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False, $oFlags = $STDOUT_CHILD)
    Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $oFlags)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc