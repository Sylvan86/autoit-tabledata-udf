#include "../TableData.au3"
#include <WinAPIConv.au3>

; create table object out of the driver informations
$mData =  _td_fromCsv(_getCmdOutput('driverquery /FO CSV',  True), ',', 0, "module|name|type|date")
_td_display($mData, "all drivers")

; filter table object to obtain file system drivers only
$mFiltered = _td_filter($mData, "$x.type = 'File System'")
_td_display($mFiltered, "file system drivers")



; run cmdline-commands and return their output
Func _getCmdOutput($sCmd, $bComspec = False, $oFlags = $STDOUT_CHILD)
	Local $iPID = Run(($bComspec ? '"' & @ComSpec & '" /c ' : "") & $sCmd, "", @SW_Hide, $oFlags)
	ProcessWaitClose($iPID)
	Return _WinAPI_OemToChar(StdoutRead($iPID))
EndFunc

