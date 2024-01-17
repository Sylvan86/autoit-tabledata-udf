#include "../TableData.au3"


#Region example for _td_getColumn
; the origin data
Global $aArray[5][4] = [["name", "age", "salary", "married"], ["Max", 25, 5000.50, True], ["Anna", 30, 6000.75, False], ["Peter", 35, 7000.25, True], ["Lena", 28, 5500.50, False]]

; convert array into table object
Global $mResult = _td_fromArray($aArray, True)

; display data
_td_display($mResult)

; sum up the salaries
MsgBox(0, "Salary sum", __Sum(_td_getColumn($mResult, "salary")))
#EndRegion




#Region helper functions
Func __Sum($aArray)
	Local $nResult = 0
	For $i = 0 To UBound($aArray) - 1
		$nResult += $aArray[$i]
	Next
	Return $nResult
EndFunc

#EndRegion