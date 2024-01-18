#include "../TableData.au3"
#include <WinAPIConv.au3>



#Region example 1 - dir-command simple
; Read data from command:
Global $sOutDirRaw = _getCmdOutput('dir /-C "' & @SystemDir & '"',  True)

; Transfer data to table type:
Global $mData = _td_fromFixWidth($sOutDirRaw, "10; 7; 9; 10;", "1-5,-1,-2")

; display data
_td_display($mData, "example 1 - dir simple")
#EndRegion



#Region example 2 - dir-command with column processing
; Read data from command:
Global $sOutDirRaw = _getCmdOutput('dir /-C "' & @SystemDir & '"',  True)

; Transfer data to table type with header and handling of columns:
Global $mData = _td_fromFixWidth($sOutDirRaw, "StringRegExpReplace($x, '(\d{2})\.(\d{2})\.(\d{4})', '$3-$2-$1') 10;" & _
											"right 7;" & _
											"(StringInStr($x, 'Dir') ? True : False) 9;" & _
											"Number 10;" & _
											"", _
											"1-5,-1,-2", "date|time|dir|size|file name")

; display data
_td_display($mData, "example 2 - dir with column processing")
#EndRegion



#Region example 3 - netstat simple
; Read data from command:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')

; Transfer data to table type:
Global $mData = _td_fromFixWidth($sNetStatRaw, _ ; input data
                                 "7;23;23;16;", _ ; column definition (here only sizes)
                                 "1-2", _  ; skip rows
								 true _    ; header
								)

; display data
_td_display($mData, "example 3 - netstat simple")
#EndRegion



#Region example 4 - netstat with column processing
; Read data from command:
Global $sNetStatRaw = _getCmdOutput('netstat -ano')

; Transfer data to table type with header and handling of columns:
Global $mData = _td_fromFixWidth($sNetStatRaw, _ ; input data
                                 "center 7;_splitIPPort 23;_splitIPPort 23;left 16;", _ ; column definition (with splitting into multiple columns)
                                 "1-2", _  ; skip rows
								 true _    ; header
								)

; display data
_td_display($mData, "example 4 - netstat with column processing")
#EndRegion



#Region helper functions
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






