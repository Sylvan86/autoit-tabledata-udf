#include "../TableData.au3"

; the origin data
Global $aArray[5][4] = [["name", "age", "salary", "married"], ["Max", 25, 5000.50, True], ["Anna", 30, 6000.75, False], ["Peter", 35, 7000.25, True], ["Lena", 28, 5500.50, False]]

; convert into a table object:
$mData = _td_fromArray($aArray, True)

; convert into primary key focused data structure:
$mTable = _td_toPrimaryKeys($mData)

; access to the data by primary key
MsgBox(0, "Anna`s salary", $mTable.Anna.salary)
