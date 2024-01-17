#include "../TableData.au3"

; #description# =================================================================================================================
; examples for using the _td_fromArray() function
; ===============================================================================================================================

#Region example 1 - simple conversion from 2D-Array to table object (header = first row)
; the origin data
Global $aArray[5][4] = [["name", "age", "salary", "married"], ["Max", 25, 5000.50, True], ["Anna", 30, 6000.75, False], ["Peter", 35, 7000.25, True], ["Lena", 28, 5500.50, False]]

; convert into a table object:
$mData = _td_fromArray($aArray, True)

; display data:
_td_display($mData, "example 1")
#EndRegion


#Region example 2 - conversion from 2D-Array to table object with own header and column processing
; the origin data
Global $aArray[4][4] = [["Max", 25, 5000.50, True], ["Anna", 30, 6000.75, False], ["Peter", 35, 7000.25, True], ["Lena", 28, 5500.50, False]]

; convert into a table object:
$mData = _td_fromArray($aArray, "name|age|salary|married", "StringUpper;$x & ' years'; $x & ' $'")

; display data:
_td_display($mData, "example 2")
#EndRegion