#include-once
#include <Array.au3>
#include <String.au3>

; #INDEX# =======================================================================================================================
; Title .........: Table data
; AutoIt Version : 3.3.16.1
; Description ...: Efficient and effective work with table data, which comes in string form.
; Author(s) .....: AspirinJunkie
; License .......: This work is free.
;                  You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License,
;                  Version 2, as published by Sam Hocevar.
;                  See http://www.wtfpl.net/ for more details.
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
;  ---- input ------
;  _td_fromString      - convert table-structured strings where the column separator can be described by a regular expression into a table object
;  _td_fromCsv         - read strings with 2D-array-like data from a string where the rows and columns separated by separator-chars (e.g.: csv or tsv)
;  _td_fromFixWidth    - read 2D-array-like data from a string where the columns have a fixed width (e.g. console outputs or printf-strings)
;  _td_fromArray       - creates a table object from an existing 2D array
;
;  ---- output  ------
;  _td_toCsv           - convert a table object into a csv formatted string
;  _td_toFixWidth      - convert a table object into a string where the columns has fixed width
;  _td_display         - present a table object like _ArrayDisplay
;  _td_toArray         - creates an array from a table object
;
;  ----- Preparation of 2D arrays for easy further processing ---
;  _td_TableToMaps     - converts a 2D-Array (rows=records, columns=values, column headers=keys) into a set of key-value maps (every record = key-value map)
;  _td_TableToDics     - converts a 2D-Array (rows=records, columns=values, column headers=keys) into a set of objects (every record = Dictionary with named attributes)
;  _td_MapsToTable     - converts a map-array (a 1D-array with maps as values) into 2 2D-array where the colums = keys
;  _td_toColumns       - convert 2D-array or table-data map from this udf into a map with column names as keys and their data as 1D-arrays
;  _td_getColumn       - extract one or multiple colums from a 2D-Array or a table-data map
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; __td_executeString                     - helper function for calling user-defined column definitions
; __td_parseAutomatic                    - helper function for automatic parsing
; __td_prepareColumnFormatting           - Prepares the definition of the user-defined functions for the column data
; __td_prepareFixedSizeColumnFormatting  - prepare the column width definition string for use in _td_fromFixWidth
; __td_realignAdditionalColumns
; __td_delRowsInString                   - delete several rows of a string
; ===============================================================================================================================


; #FUNCTION# ======================================================================================
; Name ..........: _td_fromString()
; Description ...: Convert table-structured strings where the column separator can be described by a regular expression into a table object
;                  with the ability of user-defined parsing of the values
; Syntax ........: _td_fromString($sString, [$patColDelimiter = '(?m)(?<!^|\h)\h+(?!$|\h)', [$patRowDelimiter = '\R(?!\Z)', [$nSkipRows = 0, [$vHeader = False, [$sValParseDef = "Auto", [$sFallbackParse = ($sValParseDef = "Auto") ? "auto" : Null, [$sDelim = Opt("GUIDataSeparatorChar")]]]]]]])
; Parameters ....: $sString         - The string that is to be processed
;                  $patColDelimiter - Pattern that describes the column separators
;                                     Default value = horizontal space
;                  $patRowDelimiter - Pattern that describes the row separators
;                                     Default value = any valid combination of newline characters
;                  $nSkipRows       - comma separated list of row numbers (first row = 1) or a range of row number which should be ignored (negative numbers means from behind)
;                                     example: "1,3-5,8,-1"
;                  $vHeader         - column identifier depending on the data type:
;                                     Boolean False: no header given -> results in $mRet = Null
;                                     Boolean True: first row = header row
;                                     1D-Array: column identifiers as an array (number of elements must correspond to the number of columns in $aArray)
;                                     String: column identifiers as string separated with $sDelim (number of elements must correspond to the number of columns in $aArray)
;                  $nSkipRows       - number of lines at the beginning of the file that should be skipped
;                  $sValParseDef    - column definitions either as semicolon-separated string or as 1D array
;                                     if string and no semicolon is used, then the string definition is used for all elements
;                                     the individual elements can have the following types:
;                                        - autoit function variable (prove with IsFunc()) = value is processed by this function (value is first parameter)
;                                        - "", "none", "null" = no value processing
;                                        - "void", "skip" = skip this column complete
;                                        - string with function name only = value is processed by this function (whether built-in or user-defined)
;                                        - string with "$x" in it = user-defined AutoIt code which is executed and where $x is assigned the value
;                  $sFallbackParse  - definition as in $sValParseDef as default definition if $sValParseDef = Default
;                  $sDelim          - separator char/string for the column identifiers if $vHeader is a string
; Return values .: Success: table object as map with elements:
;                                    "data": the table data as 2D-array,
;                                    "header": the column identifiers as 1D-Array,
;                                    "iCols": number of columns,
;                                    "iRows": number of data records
;                  Failure: False
;                     @error = 1: error during split into rows
;                     @error = 2: error during _td_fromArray (@extend = @error from _td_fromArray)
; Author ........: AspirinJunkie
; Last changed ..: 2024-01-16
; =================================================================================================
Func _td_fromString($sString, $patColDelimiter = '(?m)(?<!^|\h)\h+(?!$|\h)', $patRowDelimiter = '\R(?!\Z)', $nSkipRows = 0, $vHeader = False, $sValParseDef = "Auto", $sFallbackParse = ($sValParseDef = "Auto") ? "auto" : Null, $sDelim = Opt("GUIDataSeparatorChar"))
	; default values for parameters
	If IsKeyword($sValParseDef) = 1 Then $sValParseDef = "Auto"
	If IsKeyword($patColDelimiter) > 0 Or $patColDelimiter = "" Then $patColDelimiter = '(?m)(?<!^|\h)\h+(?!$|\h)'
	If IsKeyword($patRowDelimiter) > 0 Or $patRowDelimiter = "" Then $patRowDelimiter = '\R(?!\Z)'

	; skip rows in file
	If IsString($nSkipRows) Then
		$sString = __td_delRowsInString($sString, $nSkipRows)
	ElseIf $nSkipRows > 0 Then
		$sString = StringRegExpReplace($sString, '^(.*\R){' & $nSkipRows & '}', '', 1)
	EndIf

	; split string into rows
	Local $aRows = StringSplit(StringRegExpReplace($sString, $patRowDelimiter, Chr(0)), Chr(0), 3)
	If @error Then Return SetError(1, @error, Null)

	; split columns
	Local $aRet[UBound($aRows)][1], $aCols
	For $i = 0 To UBound($aRows) - 1
		$aCols = StringSplit(StringRegExpReplace($aRows[$i], $patColDelimiter, Chr(0)), Chr(0), 3)

		If UBound($aCols) > UBound($aRet, 2) Then Redim $aRet[UBound($aRet, 1)][UBound($aCols)]

		For $j = 0 To UBound($aCols) - 1
			$aRet[$i][$j] = $aCols[$j]
		Next
	Next

	; parse values and set header:
	Local $mRet = _td_fromArray($aRet, $vHeader, $sValParseDef, $sDelim, $sFallbackParse)
	If @error Then Return SetError(2, @error, Null)

	Return $mRet
EndFunc


; #FUNCTION# ======================================================================================
; Name ..........: _td_fromCsv()
; Description ...: converts a csv string or file into an array with the ability of user-defined parsing of the values
; Syntax ........: _td_fromCsv($sInput, [$cSep = ',', [$vHeader = False, [$nSkipRows = 0, [$sValParseDef = Default, [$bTrimWS = True, [$sFallbackParse = ($sValParseDef = "Auto") ? "auto" : Null, [$cQuote = '"', [$sDelim = Opt("GUIDataSeparatorChar")]]]]]]]])
; Parameters ....: $sInput         - a csv-formatted string, a file name/path or a FileRead-Handle to a csv-formatted file
;                  $cSep           - character for the value seperator (common: ";", "," or "|")
;                  $vHeader        - column identifier depending on the data type:
;                                    Boolean False: no header given -> results in $mRet = Null
;                                    Boolean True: first row = header row
;                                    1D-Array: column identifiers as an array (number of elements must correspond to the number of columns in $aArray)
;                                    String: column identifiers as string separated with $sDelim (number of elements must correspond to the number of columns in $aArray)
;                  $nSkipRows      - comma separated list of row numbers (first row = 1) or a range of row number which should be ignored (negative numbers means from behind)
;                                    example: "1,3-5,8,-1"
;                  $sValParseDef   - column definitions either as semicolon-separated string or as 1D array
;                                    if string and no semicolon is used, then the string definition is used for all elements
;                                    the individual elements can have the following types:
;                                       - autoit function variable (prove with IsFunc()) = value is processed by this function (value is first parameter)
;                                       - "", "none", "null" = no value processing
;                                       - "void", "skip" = skip this column complete
;                                       - string with function name only = value is processed by this function (whether built-in or user-defined)
;                                       - string with "$x" in it = user-defined AutoIt code which is executed and where $x is assigned the value
;                  $bTrimWS        - True: Whitespace before and after the value are not treated as a part of them
;                                  - False: Whitespaces before and after the value are treated as a part of them
;                  $sFallbackParse - definition as in $sValParseDef as default definition if $sValParseDef = Default
;                  $cQuote         - char for quoting values (e.g. when line breaks are inside the value)
;                  $sDelim         - separator char/string for the column identifiers if $vHeader is a string
; Return values .: Success: table object as map with elements:
;                                    "data": the table data as 2D-array,
;                                    "header": the column identifiers as 1D-Array,
;                                    "iCols": number of columns,
;                                    "iRows": number of data records
;                  Failure: False
;                     @error = 1: error when reading from the specified file in $sInput (@extended = @error of FileRead)
;                     @error = 2: invalid data type of $sInput
;                     @error = 3: no possibility to derive data records from $sInput
;                     @error = 4: no data records available
;                     @error = 5: error in determining the number of columns
;                     @error = 6: error during _td_fromArray() (@error in @extended)
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-18
; =================================================================================================
Func _td_fromCsv($sInput, $cSep = ',', $nSkipRows = 0, $vHeader = False, $sValParseDef = "Auto", $bTrimWS = True, $sFallbackParse = ($sValParseDef = "Auto") ? "auto" : Null, $cQuote = '"', $sDelim = Opt("GUIDataSeparatorChar"))
	If IsKeyword($sValParseDef) = 1 Then $sValParseDef = "Auto"

	Local Const $patCSV = "(?mx)(?(DEFINE)" & @LF & _
			"(?'VALUNQUOTED' [^\Q" & $cSep & "\E\v\Q" & $cQuote & "\E]*+)" & @LF & _
			"(?'VALQUOTED'  \Q" & $cQuote & "\E(?>[^\Q" & $cQuote & "\E]++|\Q" & $cQuote & $cQuote & "\E)*+\Q" & $cQuote & "\E)" & @LF & _
			"(?'VALUE'\h*\K\g<VALQUOTED>\h* | (?<=\Q" & $cSep & "\E|^)\g<VALUNQUOTED>)" & @LF & _
			"(?'RECORD' ^(?> \g<VALQUOTED> | [^\Q" & $cQuote & "\E\v]*)*+ $ )" & @LF & _
		")"
	Local Const $patValues = $bTrimWS ? "(?|\h*\Q" & $cQuote & "\E((?>[^\Q" & $cQuote & "\E]++|\Q" & $cQuote & $cQuote & "\E)*+)\Q" & $cQuote & "\E\h*|\h*([^\Q" & $cSep & "\E\v]+)|(?<=\Q" & $cSep & "\E|\A).{0})" _
							: "(?|\h*\Q" & $cQuote & "\E((?>[^\Q" & $cQuote & "\E]++|\Q" & $cQuote & $cQuote & "\E)*+)\Q" & $cQuote & "\E\h*|[^\Q" & $cSep & "\E\v]+|(?<=\Q" & $cSep & "\E|\A).{0})"

	; read file if $sInput = file name or file handle
	If FileExists($sInput) Or IsInt($sInput) Then $sInput = FileRead($sInput)
	If @error Then Return SetError(1, @error, False)
	If Not IsString($sInput) Then Return SetError(2, 0, False)

	; delete trailing empty lines
	$sInput = StringRegExpReplace($sInput, '\s+\Z', '')

	; skip rows in file
	If IsString($nSkipRows) And $nSkipRows <> "" Then
		$sInput = __td_delRowsInString($sInput, $nSkipRows)
	ElseIf $nSkipRows > 0 Then
		$sInput = StringRegExpReplace($sInput, '^(.*\R){' & $nSkipRows & '}', '', 1)
	EndIf

	; convert line ends to \n (@LF) only
	$sInput = StringRegExpReplace($sInput, '\r\n|\r', @LF)

	; determine the number of records
	Local $aRecords = StringRegExp($sInput, $patCSV & '(?&RECORD)', 3)
	If @error Then Return SetError(3, @error, False)
	Local $nRecords = UBound($aRecords)
	If $nRecords < 1 Then Return SetError(4, $nRecords, False)

	; determine the number of (initial) columns:
	StringRegExpReplace($aRecords[0], $patValues, '')
	If @error Then Return SetError(5, @error, False)
	Local $nCols = @extended

	; define the return data array
	Local $aRet[$nRecords][$nCols]

	; iterate over all records
	Local $aVals, $sVal, $iJ
	For $iI = 0 To $nRecords - 1
		$iJ = 0

		; iterate over all values in the current record
		For $sVal In StringRegExp($aRecords[$iI], $patValues, 3)
			; resize return array if current record has more values than previous ones
			If $iJ >= $nCols Then ReDim $aRet[UBound($aRet)][$iJ + 1]

			; remove leading/trailing whitespaces if set
			If $bTrimWS Then $sVal = StringStripWS($sVal, 2)

			; unescape double quotes
			$sVal = StringReplace($sVal, $cQuote & $cQuote, $cQuote, 0, 1)

			; add current value to return array
			$aRet[$iI][$iJ] = $sVal

			$iJ += 1
		Next
	Next

	; parse values and set header:
	Local $mRet = _td_fromArray($aRet, $vHeader, $sValParseDef, $sDelim, $sFallbackParse)
	If @error Then Return SetError(6, @error, Null)

	Return $mRet
EndFunc   ;==>_td_fromCsv


; #FUNCTION# ======================================================================================
; Name ..........: _td_fromFixWidth()
; Description ...: parse table-like strings with fixed column widths and
;                  extract or process their content into an array
; Syntax ........: _td_fromFixWidth($sString, $sFormat, [$vHeader = False, [$nSkipRows = 0, [$sFallbackParse = Null, $sDelim = Opt("GUIDataSeparatorChar")]]]])
; Parameters ....: $sString       - a fixed-with-columns-formatted string, a file name/path or a FileRead-handle to such a file
;                                   hint: empty lines at the beginning of the string are already removed by the function.
;                  $sFormat       - dllcall-like syntax where columns separated by ";":
;                        COLUMNTYPE XX; COLUMNTYPE XX; COLUMNTYPE XX;...
;                        Where: COLUMNTYPE:
;                                      - "", "none", "null" = no value processing
;                                      - "void", "skip" = skip this column complete
;                                      - function name only = value is processed by this function (whether built-in or user-defined)
;                                      - string with "$x" in it = user-defined AutoIt code which is executed and where $x is assigned the value
;                                      - "left", "right", "center" = left, right or center aligned string - deletes the corresponding empty chars
;                               XX: column-width as number of chars (can be left out in the last column)
;                  $nSkipRows      - comma separated list of row numbers (first row = 1) or a range of row number which should be ignored (negative numbers means from behind)
;                                    example: "1,3-5,8,-1"
;                  $vHeader        - column identifier depending on the data type:
;                                    Boolean False: no header given -> results in $mRet = Null
;                                    Boolean True: first row = header row
;                                    1D-Array: column identifiers as an array (number of elements must correspond to the number of columns in $aArray)
;                                    String: column identifiers as string separated with $sDelim (number of elements must correspond to the number of columns in $aArray)
;                  $sFallbackParse - definition as in $sValParseDef as default definition if $sValParseDef = Default
;                  $sDelim         - separator char/string for the column identifiers if $vHeader is a string (normally "|")
; Return values .: Success: table object as map with elements:
;                                    "data": the table data as 2D-array,
;                                    "header": the column identifiers as 1D-Array,
;                                    "iCols": number of columns,
;                                    "iRows": number of data records
;                  Failure: False
;                     @error = 1: error when reading from the specified file in $sInput (@extended = @error of FileRead)
;                     @error = 2: error during the processing of the column definitions (see @extended for specific @error)
;                     @error = 3: no possibility to derive data records from $sString
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-18
; =================================================================================================
Func _td_fromFixWidth($sString, $sFormat, $nSkipRows = 0, $vHeader = False, $sFallbackParse = Null, $sDelim = Opt("GUIDataSeparatorChar"))

	; read file if $sInput = file name or file handle
	If FileExists($sString) Or IsInt($sString) Then $sString = FileRead($sString)
	If @error Then Return SetError(1, @error, False)

	; delete empty lines at the beginning:
	$sString = StringRegExpReplace($sString, '^(?:\s*\r?\n)+', '', 1)

	; skip rows in file
	If IsString($nSkipRows) Then
		$sString = __td_delRowsInString($sString, $nSkipRows)
	ElseIf $nSkipRows > 0 Then
		$sString = StringRegExpReplace($sString, '^(.*\R){' & $nSkipRows & '}', '', 1)
	EndIf

	Local Const $patColWidths = '(?>(?>^|;)\h*|[^;]\h+)\K(\d+)(?=;|$)'
	Local Const $patDelimiters = '"(?>[^"]+|"")*"(*SKIP)(*FAIL)|;'

	StringRegExpReplace($sFormat, $patDelimiters, ';')
	Local $nCols = @extended + 1

	; extract column width
	Local $aColumnWidths = StringRegExp($sFormat, $patColWidths, 3)
	If @error Or UBound($aColumnWidths) < 1 Then Return SetError(2, @error, Null)

	; conclusive or open
	If StringRegExp($sFormat, ';\h*$') Then
		Redim $aColumnWidths[UBound($aColumnWidths) + 1]
		$aColumnWidths[UBound($aColumnWidths) - 1] = -1
	EndIf

	; prepare column parsing
	$sFormat = StringRegExpReplace($sFormat, '(?>(?>^|;)\h*|[^;])\K(\h*\d+)(?=;|$)', '')

	; prepare special fixed-width functions:
	$sFormat = StringRegExpReplace($sFormat, '(?i)\b(rightstring|right)\b', 'StringStripWS($x, 1)')
	$sFormat = StringRegExpReplace($sFormat, '(?i)\b(leftstring|left)\b', 'StringStripWS($x, 2)')
	$sFormat = StringRegExpReplace($sFormat, '(?i)\b(centerstring|center)\b', 'StringStripWS($x, 3)')

	; process string
	Local $aSplit = StringRegExp($sString, "([^\r\n|\n|\r]+)", 3)
	If @error Then Return SetError(3, @error, Null)

	; fill data array
	Local $aData[UBound($aSplit)][$nCols], $iStart, $sLine
	For $i = 0 To UBound($aSplit) - 1
		$iStart = 1
		$sLine = $aSplit[$i]

		For $j = 0 To UBound($aColumnWidths) - 1
			$aData[$i][$j] = StringMid($sLine, $iStart, $aColumnWidths[$j])
			$iStart += $aColumnWidths[$j]
		Next
	Next

	; parse values and set header:
	Local $mRet = _td_fromArray($aData, $vHeader, $sFormat, $sDelim, $sFallbackParse)
	If @error Then Return SetError(6, @error, Null)

	Return $mRet
EndFunc   ;==>_td_fromFixWidth


; #FUNCTION# ======================================================================================
; Name ..........: _td_fromArray()
; Description ...: converts an array into a table object
; Syntax ........: _td_fromArray($aArray, $vHeader = False, $sDelim = Opt("GUIDataSeparatorChar"))
; Parameters ....: $aArray         - the 1D/2D array to be converted
;                  $vHeader        - column identifier depending on the data type:
;                                    Boolean False: no header given -> results in $mRet = Null
;                                    Boolean True: first array row = header row
;                                    1D-Array: column identifiers as an array (number of elements must correspond to the number of columns in $aArray)
;                                    String: column identifiers as string separated with $sDelim (number of elements must correspond to the number of columns in $aArray)
;                  $sValParseDef   - column definitions either as semicolon-separated string or as 1D array
;                                    if string and no semicolon is used, then the string definition is used for all elements
;                                    the individual elements can have the following types:
;                                       - autoit function variable (prove with IsFunc()) = value is processed by this function (value is first parameter)
;                                       - "", "none", "null" = no value processing
;                                       - "void", "skip" = skip this column complete
;                                       - string with function name only = value is processed by this function (whether built-in or user-defined)
;                                       - string with "$x" in it = user-defined AutoIt code which is executed and where $x is assigned the value
;                  $sDelim         - separator char/string for the column identifiers if $vHeader is a string
;                  $sFallbackParse - definition as in $sValParseDef as default definition if $sValParseDef = Default
; Return values .: Success: table object as map with elements:
;                                    "data": the table data as 2D-array,
;                                    "header": the column identifiers as 1D-Array,
;                                    "iCols": number of columns,
;                                    "iRows": number of data records
;                  Failure: False
;                     @error = 1: wrong dimension of input array $aArray (only 1D/2D-array)
;                     @error = 2: error when splitting the header string (@extended = @error of StringSplit)
;                     @error = 3: number of header elements in the string $vHeader does not match the number of array columns
;                     @error = 4: wrong dimension of input Header-array (only 1D-array possible)
;                     @error = 5: number of header elements in the array $vHeader does not match the number of array columns
;                     @error = 6: wrong datatype for $vHeader (only boolean, array, string)
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-18
; =================================================================================================
Func _td_fromArray($aArray, $vHeader = False, $sValParseDef = Default, $sDelim = Opt("GUIDataSeparatorChar"), $sFallbackParse = ($sValParseDef = "Auto") ? "auto" : Null)
	Local $mRet[]
	Local $nDims = UBound($aArray, 0), $nRows = UBound($aArray, 1), $nCols = UBound($aArray, 2)
	If $nDims = 1 Then $nCols = 1
	Local $iHeaderRows = (IsBool($vHeader) And $vHeader = True) ? 1 : 0

	If $nDims < 1 Or $nDims > 2 Then Return SetError(1, $nDims, False)

	; handle the header parameter
	Switch VarGetType($vHeader)
		Case "String"
			If $nDims = 1 Then
				Local $aHeader[1] = [$vHeader]
				$mRet.Header = $aHeader
			Else
				$mRet.Header = StringSplit($vHeader, $sDelim, 3)
				If @error Then Return SetError(2, @error, False)
				If UBound($mRet.Header) < $nCols Then Return SetError(3, UBound($mRet.Header), False)
			EndIf

		Case "Array"
			If UBound($vHeader, 0) <> 1 Then Return SetError(4, UBound($vHeader, 0), False)
			If UBound($vHeader, 1) < $nCols Then Return SetError(5, UBound($vHeader, 0), False)
			$mRet.Header = $vHeader

		Case "Bool"
			If $vHeader = True Then ; 1st row = header row
				Local $aHeader[$nCols]
				If $nDims = 1 Then
					$aHeader[0] = StringStripWS($aArray[0], 3)
				Else
					For $i = 0 To $nCols - 1
						$aHeader[$i] = StringStripWS($aArray[0][$i], 3)
					Next
				EndIf
				$mRet.Header = $aHeader
			Else
				$mRet.Header = Null
			EndIf

		Case Else
			Return SetError(6, 0, False)

	EndSwitch

	; handle data array
	If $nDims = 1 Then ; convert to 2D-Array
		Local $aData[$nRows - $iHeaderRows][1]
		For $i = $iHeaderRows To $nRows - 1
			$aData[$i - $iHeaderRows][0] = $aArray[$i]
		Next
		; set data attribute
		$mRet.Data = $aData
	Else
		If $vHeader = 1 Then _ArrayDelete($aArray, 0) ; remove first row
		$mRet.Data = $aArray
	EndIf

	; add dimension attributes
	$mRet.nCols = $nCols
	$mRet.nRows = UBound($mRet.Data, 1)

	; parse and process the data elements:
	If IsKeyword($sValParseDef) <> 1 Then ; <> Default
		Local $aData = $mRet.Data
		Local $aSubColumns[$nCols]
		Local $bWithArrays = False
		Local $aColDefs = __td_prepareColumnFormatting($sValParseDef, $nCols, $sFallbackParse)
		If @error Then Return SetError(7, @error, False)

		For $iCol = Ubound($aColDefs) -1 To 0 Step - 1
			Local $fParse = $aColDefs[$iCol]

			If IsKeyword($fParse) = 2 Then ; no handling
				ContinueLoop

			ElseIf IsString($fParse) Then ; autoit-code as string or skipping
				; don't parse column
				If $fParse = "" Or $fParse = "null" or $fParse = "none" Then ContinueLoop

				; skip column complete:
				If $fParse = "void" Or $fParse = "skip" Then
					_ArrayColDelete($aData, $iCol)
					_ArrayDelete($aSubColumns, $iCol)
					Local $aHeader = $mRet.Header
					_ArrayDelete($aHeader, $iCol)
					$mRet.Header = $aHeader
					ContinueLoop
				EndIf

				; autoit-code as string
				For $j = 0 To UBound($mRet.Data, 1) - 1
					Local $sVal = __td_executeString($fParse, $aData[$j][$iCol])
					;~ If @error Then Return SetError(8, @error, False)

					; check if value is a 1D-Array - then add new result columns
					If IsArray($sVal) Then
						If UBound($sVal, 0) <> 1 Then ContinueLoop
						$bWithArrays = True
						If $aSubColumns[$iCol] < UBound($sVal) Then $aSubColumns[$iCol] = UBound($sVal)
					EndIf
					$aData[$j][$iCol] = $sVal
				Next

			ElseIf IsFunc($fParse) Then
				For $j = 0 To UBound($mRet.Data, 1) - 1
					Local $sVal = Call($fParse, $aData[$j][$iCol])

					; check if value is a 1D-Array - then add new result columns
					If IsArray($sVal) Then
						If UBound($sVal, 0) <> 1 Then ContinueLoop
						$bWithArrays = True
						If $aSubColumns[$iCol] < UBound($sVal) Then $aSubColumns[$iCol] = UBound($sVal)
					EndIf
					$aData[$j][$iCol] = $sVal
				Next

			EndIf

		Next

		; case that a user-defined function returns an array - we have to resize the number of columns
		If $bWithArrays Then
			$mRet.Header = __td_realignAdditionalColumns($aSubColumns, $aData, $mRet.Header)
		EndIf

		$mRet.Data = $aData
	EndIf

	Return $mRet
EndFunc


; #FUNCTION# ======================================================================================
; Name ..........: _td_display()
; Description ...: displays an table object with ArrayDisplay
; Syntax ........: _td_display(ByRef $mTable, $sTitle = "Table" , $sSep = Opt("GUIDataSeparatorChar"))
; Parameters ....: $mTable         - table object structured like in this udf
;                  $sTitle         - title text for the window
;                  $sSep           - separator char/string used to delimit the header elements
; Return values .: Success: 1
;                  Failure: 0
;                     @error = 1: no table data object in $mTable
;                     @error = 2: error during _ArrayDisplay (@extended = @error of _ArrayDisplay)
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-18
; =================================================================================================
Func _td_display(ByRef $mTable, $sTitle = "Table" , $sSep = Opt("GUIDataSeparatorChar"))
	If Not IsMap($mTable) Or Not MapExists($mTable, "Header") Or Not MapExists($mTable, "Data") Then Return SetError(1,0,0)

	Local $aHeader = $mTable.Header
	Local $sHeader = $aHeader = Null ? "" : _ArrayToString($aHeader, $sSep)
	_ArrayDisplay($mTable.Data, $sTitle, "", 16 + 64, $sSep, $sHeader)
	If @error Then Return SetError(2, @error, 0)

	Return 1
EndFunc


; #FUNCTION# ======================================================================================
; Name ..........: _td_toCsv()
; Description ...: converts a 2D-Array (rows=records, columns=values) into a csv-style string
; Syntax ........: _td_toCsv($aArray, [$sHeader = Default, [$cSep = ';', [$cQuote = '', [$sLB = @CRLF]]]])
; Parameters ....: $mTable        - the input table object
;                  $bHeader       - Include header in output - yes (True) or no (False)
;                  $cSep          - character for the value seperator (common: ";", "," or "|")
;                  $cQuote        - character for the quotation character (common: '"') - if already inside value than escaped through doubling
;                  $sLB           - String which is used for line-breaks (common: @CRLF)
;                  $bQuoteAlways  - when true each value is set in quotes
; Return values .: Success:       csv-formatted string
;                  Failure: False
;                     @error = 1: $aArray is not a 2D-Array (@extended = num of dimensions of $aArray)
;                     @error = 2: input array for $sHeader has not array dimension 1
; Author ........: AspirinJunkie
; Last changed ..: 2020-07-31
; =================================================================================================
Func _td_toCsv($mTable, $bHeader = True, $cSep = ';', $cQuote = '"', $sLB = @CRLF, $bQuoteAlways = False)
	If Not IsMap($mTable) Or Not MapExists($mTable, "Header") Or Not MapExists($mTable, "Data") Then Return SetError(1,0,0)

	Local $aHeader = $mTable.Header
	Local $aData = $mTable.Data

	Local $sRet = ""

	; add header
	If $bHeader Then
		For $sV In $aHeader
			If $bQuoteAlways Or StringRegExp($sV, '[\n\r\Q' & $cSep & $cQuote & '\E]') Then
				$sV = $cQuote & StringRegExpReplace($sV, '\Q' & $cQuote & '\E', $cQuote & $cQuote) & $cQuote
			EndIf
			$sRet &= $sV & $cSep
		Next
		$sRet = StringTrimRight($sRet, StringLen($cSep)) & $sLB
	EndIf

	; add values
	Local $sV
	For $iR = 0 To UBound($aData) - 1
		For $iC = 0 To UBound($aData, 2) - 1
			$sV = $aData[$iR][$iC]
			If $bQuoteAlways Or StringRegExp($sV, '[\n\r\Q' & $cSep & $cQuote & '\E]') Then
				$sV = $cQuote & StringRegExpReplace($sV, '\Q' & $cQuote & '\E', $cQuote & $cQuote) & $cQuote
			EndIf
			;~ If StringRegExp($sV, '\R|[\Q' & $cSep & $cQuote & '\E]') Then
			;~ 	$sV = $cQuote = "" _
			;~ 			 ? '"' & StringReplace($sV, '"', '""', 0, 1) & '"' _
			;~ 			 : $cQuote & StringReplace($sV, $cQuote, $cQuote & $cQuote, 0, 1) & $cQuote
			;~ EndIf
			$sRet &= $sV & $cSep
		Next
		$sRet = StringTrimRight($sRet, StringLen($cSep)) & $sLB
	Next

	Return StringTrimRight($sRet, StringLen($sLB))

EndFunc   ;==>_td_toCsv


; #FUNCTION# ======================================================================================
; Name ..........: _td_toFixWidth()
; Description ...: converts a 2D-Array (rows=records, columns=values) into a string with fixed with sizes for the columns
; Syntax ........: _td_toFixWidth(ByRef $aArray, $vWidths = Default, $sColSep = " ", $bAlignLeft = False, $sLineSep = @CRLF, $sHeadersep = Default)
; Parameters ....: $mTable        - the input table object
;                  $vWidths       - widths for every column
;                                   $vWidths = Default: the column widths are automatically determined based on the largest elements in the respective column.
;                                   $vWidths = Array: column widths as 1D-array
;                                   $vWidths = IsString: string with pipe (|) separated column widths
;                                              If only individual widths are specified, the others are determined on the basis of the data - example: "|10|20|||12|5"
;                  $sColSep       - a optional column separator
;                  $bAlignleft    - alignment of values inside the column
;                  $sLineSep      - row separator - normally some kind of line break
;                  $sHeadersep    - header separation character - would be repeated over the whole width
; Return values .: Success:       fixed-with formatted string
;                  Failure: False
;                     @error = 1: $aArray is not a 2D-Array (@extended = num of dimensions of $aArray)
;                     @error = 2: invalid value for $vWidths
;                     @error = 3: dimension error between size of $vWidths and number of columns
; Author ........: AspirinJunkie
; Last changed ..: 2020-07-31
; =================================================================================================
Func _td_toFixWidth(ByRef $mTable, $vWidths = Default, $bHeader = True, $sColSep = " ", $bAlignLeft = False, $sLineSep = @CRLF, $sHeadersep = Default)
	If Not IsMap($mTable) Or Not MapExists($mTable, "Header") Or Not MapExists($mTable, "Data") Then Return SetError(1,0,0)

	Local $aHeader = $mTable.Header
	Local $aData = $mTable.Data

	; process the column widths or determine them by the data
	Select
		Case IsString($vWidths)
			Local $aWidths = StringSplit($vWidths, "|", 2 + 1)
			If UBound($aWidths) < UBound($aData, 2) Then Redim $aWidths[UBound($aData, 2)]
		Case UBound($vWidths, 0) = 1
			Local $aWidths = $vWidths
			If UBound($aWidths) < UBound($aData, 2) Then Redim $aWidths[UBound($aData, 2)]
		Case IsKeyword($vWidths) = 1
			Local $aWidths[UBound($aData, 2)]

			; check the maximum size of the data per column
			For $j = 0 To UBound($aData, 2) - 1
				For $i = 0 To UBound($aData, 1) - 1
					If $aWidths[$j] < StringLen($aData[$i][$j]) Then $aWidths[$j] = StringLen($aData[$i][$j])
				Next
				; check also the header
				If $bHeader And ($aWidths[$j] < StringLen($aHeader[$j])) Then $aWidths[$j] = StringLen($aHeader[$j])
			Next
		Case Else
			Return SetError(2, UBound($vWidths, 0), Null)
	EndSelect

	; determine width if not set by user
	For $j = 0 To Ubound($aWidths) - 1
		If $aWidths[$j] < 1 Then
			For $i = 0 To UBound($aData, 1) - 1
				If $aWidths[$j] < StringLen($aData[$i][$j]) Then $aWidths[$j] = StringLen($aData[$i][$j])
			Next
			; check also the header
			If $bHeader And ($aWidths[$j] < StringLen($aHeader[$j])) Then $aWidths[$j] = StringLen($aHeader[$j])
		EndIf
	Next

	; prepare and check column-width-array:
	If UBound($aWidths) <> UBound($aData, 2) Then Return SetError(3, UBound($aWidths), Null)
	Local $dFullWidth = 0
	For $i = 0 To UBound($aWidths) - 1
		$aWidths[$i] = Int($aWidths[$i])
		If $aWidths[$i] < 1 Then Return SetError(4, $i, Null)
		$dFullWidth += $aWidths[$i]
	Next
	$dFullWidth += StringLen($sColSep) * (UBound($aWidths) - 1)

	; build the output String:
	Local $sRet = ""

	; write header
	If $bHeader Then
		For $i = 0 To UBound($aHeader) - 1
			$sRet &= StringFormat( "%" & ($bAlignLeft ? "-" : "") & $aWidths[$i] & "s" & "%s" , $aHeader[$i], $sColSep)
		Next
		$sRet &= $sLineSep
	EndIf

	; write header sep
	If IsKeyword($sHeadersep) <> 1 Then $sRet &= _StringRepeat(StringLeft($sHeadersep, 1), $dFullWidth) & $sLineSep

	; write columns
	For $i = 0 To UBound($aData, 1) - 1
		For $j = 0 To UBound($aData, 2) - 1
			$sRet &= StringFormat( "%" & ($bAlignLeft ? "-" : "") & $aWidths[$j] & "s" & "%s" , $aData[$i][$j], $sColSep)
		Next
		If StringLen($sColSep) > 0 Then $sRet = StringTrimRight($sRet, StringLen($sColSep))
		$sRet &= $sLineSep
	Next

	Return SetExtended(UBound($aData, 1), StringTrimRight($sRet, StringLen($sLineSep)))
EndFunc


; #FUNCTION# ======================================================================================
; Name ..........: _td_TableToMaps()
; Description ...: converts a table object into a set of key-value maps (every record = key-value map)
; Syntax ........: _td_TableToMaps($mTable)
; Parameters ....: $mTable        - table object structured like in this udf
; Return values .: Success:       1D-array with record-objects of type Map
;                  Failure: False
;                     @error = 1: $mTable is not a valid table object
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-21
; =================================================================================================
Func _td_TableToMaps($mTable)
	If Not IsMap($mTable) Or Not MapExists($mTable, "Header") Or Not MapExists($mTable, "Data") Then Return SetError(1,0,0)

	Local $aHeader = $mTable.Header
	Local $aData = $mTable.Data

	; prepare return Array
	Local $aRet[UBound($aData)]

	For $iI = 0 To UBound($aData) - 1
		Local $mMap[]
		For $iJ = 0 To UBound($aData, 2) - 1
			$mMap[$aHeader[$iJ]] = $aData[$iI][$iJ]
		Next
		$aRet[$iI] = $mMap
	Next

	Return $aRet
EndFunc   ;==>_td_TableToMaps


; #FUNCTION# ======================================================================================
; Name ..........: _td_TableToDics()
; Description ...: converts a table object into a set of key-value dictionaries (every record = key-value map)
; Syntax ........: _td_TableToDics($aArray, [$sHeader = Default, [$bHeader = False]])
; Parameters ....: $mTable        - table object structured like in this udf
; Return values .: Success:       1D-array with record-objects of type Scripting.Dictionary
;                  Failure: False
;                     @error = 1: $mTable is not a valid table object
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-21
; =================================================================================================
Func _td_TableToDics($mTable)
	If Not IsMap($mTable) Or Not MapExists($mTable, "Header") Or Not MapExists($mTable, "Data") Then Return SetError(1,0,0)

	Local $aHeader = $mTable.Header
	Local $aData = $mTable.Data

	; prepare return Array
	Local $aRet[UBound($aData)]

	Local $oDic
	For $iI = 0 To UBound($aData) - 1
		$oDic = ObjCreate("Scripting.Dictionary")
		For $iJ = 0 To UBound($aData, 2) - 1
			$oDic($aHeader[$iJ]) = $aData[$iI][$iJ]
		Next
		$aRet[$iI] = $oDic
	Next

	Return $aRet
EndFunc   ;==>_td_TableToDics



; #FUNCTION# ======================================================================================
; Name ..........: _td_MapsToTable()
; Description ...: converts a map-array (a 1D-array with maps as values) into a table object
; Syntax ........: _td_MapsToTable($aMapArray)
; Parameters ....: $aMapArray     - the input map-array (1D-array with maps as values)
; Return values .: Success:       2D-array
;                  Failure: Null
;                     @error = 1: aMapArray is not a array
;                     @error = 2: array-value is not a map (@extend = index of wrong value)
; Author ........: AspirinJunkie
; Last changed ..: 2022-09-26
; Version .......: 0.5
; =================================================================================================
Func _td_MapsToTable($aMapArray)
	If UBound($aMapArray, 0) <> 1 Then Return SetError(1, UBound($aMapArray, 0) <> 1, Null)

	Local $mHeaders[], $aResult[1][1]
	Local $mMap, $sKey, $sAttribute

	Local $iRow = 0, $nAttribs = 0
	For $mMap In $aMapArray
		If Not IsMap($mMap) Then Return SetError(2, $iRow, Null)

		For $sKey In MapKeys($mMap)
			If Not MapExists($mHeaders, $sKey) Then
				$mHeaders[$sKey] = $nAttribs
				$nAttribs += 1
				If UBound($aResult, 2) < $nAttribs Then Redim $aResult[UBound($aResult, 1)][UBound($aResult, 2) * 2]
			EndIf

			If UBound($aResult, 1) <= $iRow Then Redim $aResult[UBound($aResult, 1) * 2][UBound($aResult, 2)]

			$aResult[$iRow][$mHeaders[$sKey]] = $mMap[$sKey]
		Next
		$iRow += 1
	Next

	Redim $aResult[$iRow][$nAttribs]

	Local $aHeader[UBound($mHeaders)]
	For $sAttribute In MapKeys($mHeaders)
		$aHeader[$mHeaders[$sAttribute]] = $sAttribute
	Next

	Local $mRet[]
	$mRet["Data"] = $aResult
	$mRet["Header"] = $aHeader

	Return $mRet
EndFunc   ;==>_td_MapsToTable

; #FUNCTION# ======================================================================================
; Name ..........: _td_toColumns()
; Description ...: convert 2D-array or table-data map from this udf into a map with column names as keys and their data as 1D-arrays
;                  = easy access to column data with $mResult.colName
; Syntax ........: _td_toColumns($vData, $vHeader = Default)
; Parameters ....: $vData     - a table-data map with Data/Header attribute like returned from _td_fromFixWidth, _td_fromCsv or _td_fromArray
; Return values .: Success: map with column names as keys and their data as 1D-arrays
;                  Failure: Null
;                     @error = 1: error during validate Data-attribute of $mTable
;                     @error = 2: error during validate header-attribute of $mTable
; Author ........: AspirinJunkie
; =================================================================================================
Func _td_toColumns($mTable)
	; validate $vData
	If Not MapExists($mTable, "Data") Then Return SetError(1, 0, Null)
	If Not MapExists($mTable, "Header") Then Return SetError(2, 0, Null)
	Local $aHeader = $mTable.Header
	Local $aData = $mTable.Data

	; build return map
	Local $mRet[] ; empty map for returning
	Local $sColName
	For $i = 0 To Ubound($aData, 2) - 1
		$sColName = $aHeader[$i]
		Local $aColumn[UBound($aData, 1)]

		For $j = 0 To UBound($aData, 1) - 1
			$aColumn[$j] = $aData[$j][$i]
		Next
		$mRet[$sColName] = $aColumn
	Next

	Return $mRet
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _td_getColumn()
; Description ...: extract one or multiple colums from a 2D-Array or a table-data map (defined in this udf)
; Syntax ........: _td_getColumn($vData, $vColumn, $vHeader = Default)
; Parameters ....: $vData     - 2D-Array or a map with data/header attribute like returned from _td_fromFixWidth or _td_fromCsv
;                  $vColumn   - single column selector: a column name (see $vHeader definition) or a array column integer index
;                               multiple column select: array of single column selectors or semicolon separated column names
;                  $vHeader   - Default: header = first row of 2D-data-array or the header-attribute of table-data map
;                               Array:   column names as 1D-Array in column order
;                               String:  semicolon separated column names in column order
;                               Map:     ["column name": column index, ...]
; Return values .: Success: 1D/2D-array with row-data depends on single or multiple column selector 
;                  Failure: Null
;                     @error = 1: error during validate $vData (@extended to narrow further)
;                     @error = 2: error during validate $vHeader (@extended to narrow further)
;                     @error = 3: error during validate $vColumn (@extended to narrow further)
; Author ........: AspirinJunkie
; =================================================================================================
Func _td_getColumn($mTable, $vColumn, $vHeader = Default)
	If Not IsMap($mTable) Or Not MapExists($mTable, "Header") Or Not MapExists($mTable, "Data") Then Return SetError(1,0,0)

	Local $aHeader = $mTable.Header
	Local $aData = $mTable.Data

	; validate and process $aHeader
	Local $mHeader[]
	For $i = 0 To UBound($aHeader, 1) - 1
		$mHeader[$aHeader[$i]] = $i
	Next

	; validate column selector
	If StringInStr($vColumn, ';', 1,1,2) Then $vColumn = StringSplit($vColumn, ";", 3)
	Select
		Case UBound($vColumn, 0) = 1
			For $vColIdentifier In $vColumn
				If IsString($vColIdentifier) Then
					If Not MapExists($mHeader, $vColIdentifier) Then Return SetError(3, 3, Null)
				ElseIf IsInt($vColIdentifier) Then
					If $vColIdentifier < 0 Or $vColIdentifier >= UBound($aData, 2) Then Return SetError(3, 4, Null)
				Else
					 Return SetError(3, 2, Null)
				EndIf
			Next
		Case IsString($vColumn)
			If Not MapExists($mHeader, $vColumn) Then Return SetError(3, 5, Null)
		Case IsInt($vColumn)
			If $vColumn < 0 Or $vColumn >= UBound($aData, 2) Then Return SetError(3, 6, Null)
		Case Else ; wrong type for the column selector in $vcolumn
			SetError(3, 1, Null)
	EndSelect

	; process column selection
	If IsArray($vColumn) Then ; multiple values
		Local $iStart = (IsKeyword($vHeader) = 1) ? 1 : 0
		Local $aRet[UBound($aData, 1) - $iStart][UBound($vColumn)]

		Local $aColumns[UBound($vColumn)]
		For $i = 0 To UBound($vColumn) - 1
			$aColumns[$i] = IsString($vColumn[$i]) ? $mHeader[$vColumn[$i]] : $vColumn[$i]
		Next

		For $j = 0 To UBound($aColumns) - 1
			Local $iColumn = $aColumns[$j]
			For $i = $iStart To UBound($aData, 1) - 1
				$aRet[$i - $iStart][$j] = $aData[$i][$iColumn]
			Next
		Next
		Return $aRet
	Else ; scalar / single column selector
		Local $iStart = (IsKeyword($vHeader) = 1) ? 1 : 0
		Local $aRet[UBound($aData, 1) - $iStart]

		Local $iColumn = IsString($vColumn) ? $mHeader[$vColumn] : $vColumn
		For $i = $iStart To UBound($aData, 1) - 1
			$aRet[$i - $iStart] = $aData[$i][$iColumn]
		Next
		Return $aRet
	EndIf

EndFunc

















#region helper functions

; #INTERNAL_USE_ONLY# ======================================================================================
; Name ..........: __td_prepareColumnFormatting()
; Description ...: converts a csv string or file into an array with the ability of user-defined parsing of the values
; Syntax ........: __td_prepareColumnFormatting($vColDef, $bWithColWidth = False)
; Parameters ....: $vColDef        - column definitions either as semicolon-separated string or as 1D array
;                                    if string and no semicolon is used, then the string definition is used for all elements
;                                    the individual elements can have the following types:
;                                      - autoit function variable (prove with IsFunc()) = value is processed by this function
;                                      - "", "none", "null", "void" = no value processing
;                                      - string with function name only = value is processed by this function (whether built-in or user-defined)
;                                      - string with "$x" in it = user-defined AutoIt code which is executed and where $x is assigned the value
;                  $nCols          - total number of columns (to fill up lacking column definitions)
;                  $sFallback - if true, then none defined is replaced by __td_parseAutomatic - else null
; Return values .: Success: an array with the prepared column definitions as 1D-Array
;                  Failure: Null
;                     @error = 1: wrong datatype for $vColDef
;                     @error = 2: invalid column definition as string
; Remarks .......: If definition for a column doesn't match one of the types described, then the definition falls back to null
; Author ........: AspirinJunkie
; Last changed ..: 2023-02-10
; ==========================================================================================================
Func __td_prepareColumnFormatting($vColDef, $nCols, $sFallback = "auto")
	Local $patFuncNameOnly = '^\h*[[:alnum:]\_]+\h*$'
	Local $patNoFunc = '(?i)^\h*(?>none|null)?\h*$'
	Local $patUserDefinedFunc = '\$[xX]\b'
	Local $patAutoParsing = '(?i)^\h*auto\h*$'
	Local $patVoid = '(?i)^\h*(void|skip)\h*$'
	Local $i

	; derive definition arrray
	If IsString($vColDef) Then ; definition as semicolon separated string values
		Local $aDefinitions = StringSplit($vColDef, ';', 3)
		If @error Then ; one definition for all columns
			Local $aDefinitions[$nCols]
			For $i = 0 To UBound($aDefinitions) - 1
				$aDefinitions[$i] = $vColDef
			Next
		EndIf
	ElseIf UBound($vColDef, 0) = 1 Then ; definition already as array
		Local $aDefinitions = $vColDef
	Else ; wrong type for $vColDef
		Return SetError(1, 0, Null)
	EndIf

	; fill definition list to the number of columns
	If UBound($aDefinitions) <> $nCols Then
		Local $nOld = UBound($aDefinitions)
		Redim $aDefinitions[$nCols]
		For $i = $nOld To UBound($aDefinitions) - 1
			If $aDefinitions[$i] = "" Then $aDefinitions[$i] = $sFallback
		Next
	EndIf


	; process the single column definition values
	For $i = 0 To UBound($aDefinitions) - 1

		; fallback-value if not explicitly defined
		If StringRegExp($aDefinitions[$i], $patNoFunc) Then $aDefinitions[$i] = $sFallback

		; distinguish the different definition types
		If IsFunc($aDefinitions[$i]) Then ; func variable
			$aDefinitions[$i] = $aDefinitions[$i]

		ElseIf StringRegExp($aDefinitions[$i], $patVoid) Then ; "void" = skip this column complete
			$aDefinitions[$i] = "void"

		ElseIf StringRegExp($aDefinitions[$i], $patAutoParsing) Then ; automatic parsing
			$aDefinitions[$i] = __td_parseAutomatic

		ElseIf StringRegExp($aDefinitions[$i], $patFuncNameOnly) Then ; function name
			$aDefinitions[$i] = Execute(StringStripWS($aDefinitions[$i], 3))
			If @error Or (Not IsFunc($aDefinitions[$i])) Then $aDefinitions[$i] = Null

		ElseIf StringRegExp($aDefinitions[$i], $patUserDefinedFunc) Then ; autoit user-defined code with $x as column value
			$aDefinitions[$i] = $aDefinitions[$i]

		Else
			$aDefinitions[$i] = Null
		EndIf
	Next

	Return $aDefinitions
EndFunc


Func __td_realignAdditionalColumns($aSubColumns, ByRef $aData, $aHeader = Default)
	Local $nColsNew = 0, $nColsOld = UBound($aSubColumns)
	For $i = 0 To UBound($aSubColumns) - 1
		$nColsNew += $aSubColumns[$i] = "" ? 1 : $aSubColumns[$i]
	Next
	Redim $aData[UBound($aData)][$nColsNew]
	If IsArray($aHeader) Then Redim $aHeader[$nColsNew]

	Local $iColNew = $nColsNew - 1
	For $iCol = $nColsOld - 1 To 0 Step -1

		; realign the data because of the additional columns
		For $iRow = 0 To UBound($aData, 1) - 1
			If $aSubColumns[$iCol] < 1 Then
				$aData[$iRow][$iColNew] = $aData[$iRow][$iCol]
			Else ; Array
				Local $aTmp = $aData[$iRow][$iCol]
				If UBound($aTmp, 0) <> 1 Then ; if one cell returns scalar instead of array
					Local $aTmp[$aSubColumns[$iCol]] = [$aData[$iRow][$iCol]]
				EndIf
				If UBound($aTmp) <= $aSubColumns[$iCol] Then Redim $aTmp[$aSubColumns[$iCol]]

				For $iEl = 0 To $aSubColumns[$iCol] - 1
					$aData[$iRow][$iColNew - $aSubColumns[$iCol] + 1 + $iEl] = $aTmp[$iEl]
				Next
			EndIf
		Next

		; realign the header because of the additionals columns
		If IsArray($aHeader) Then
			If $aSubColumns[$iCol] < 2 Then
				$aHeader[$iColNew] = $aHeader[$iCol]
			Else
				For $iEl = $aSubColumns[$iCol] - 1 To 0 Step - 1
					$aHeader[$iColNew - $aSubColumns[$iCol] + 1 + $iEl] = $aHeader[$iCol] & "." & $iEl + 1
				Next
			EndIf
		EndIf

		$iColNew -= $aSubColumns[$iCol] = "" ? 1 : $aSubColumns[$iCol]
	Next
	If IsArray($aHeader) Then Return $aHeader
	Return ""
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: __td_delRowsInString()
; Description ...: deletes several rows by her number in a string
; Syntax ........: __td_delRowsInString($sString, $sRows)
; Parameters ....: $sString        - the string where the rows should be deleted
;                  $sRows          - comma separated list of row numbers (first row = 1) or a range of row number
;                                    example: "1,3-5,8"
; Return values .: Success: the string without the given rows
;                  Failure: ""
;                     @error = 1: wrong format for $sRows
;                     @error = 2: invalid definition of a range (from > to)
; Author ........: AspirinJunkie
; Last changed ..: 2023-12-22
; =================================================================================================
Func __td_delRowsInString($sString, $sRows, $bDelTrailingLineBreaks = True)
	If Not StringRegExp($sRows, '^(?!-?0)((-?\d+|\d+\h*-\h*\d+)([,;\|]|\Z))*\h*$') Then Return SetError(1,0,"")

	If $bDelTrailingLineBreaks Then $sString = StringRegExpReplace($sString, '\R+\Z', '', 1)

	; decrement the numbers by 1
	;~ $sRows = Execute(StringRegExpReplace("'" & $sRows & "'", '(\d+)', "' & $1-1 & '"))

	; prepare the
	Local $aSplits = StringSplit($sRows, ',', 3)
	Local $mRows[], $iMaxRow = 0, $nStringLines = 0, $iRow
	For $sRow In $aSplits
		If StringRegExp($sRow, '\d\h*-\h*\d') Then
			Local $aRange = StringSplit($sRow, '-', 3)
			Local $iFrom = Int($aRange[0]), $iTo = Int($aRange[1])
			If $iTo < $iFrom Then Return SetError(2,0,"")
			For $i = $iFrom To $iTo
				$mRows[$i] = ""
			Next
			If $iTo > $iMaxRow Then $iMaxRow = $iTo
		Else
			$iRow = Int($sRow)

			; case negative row = count from end of string
			If $iRow < 0 Then
				If $nStringLines = 0 Then
					; count lines of file
					StringRegExpReplace($sString, '\R(?!\Z)', '$1')
					$nStringLines = @extended + 1
				EndIf
				$iRow = $nStringLines + $iRow + 1

			EndIf

			$mRows[$iRow] = ""
			If $iRow > $iMaxRow Then $iMaxRow = $iRow
		EndIf
	Next

	; determine line break char
	Local $aRE = StringRegExp($sString, "\R", 1)
	If @error Then SetError(3, @error)
	Local $cLB = $aRE[0] ; the used line break char

	; split the string at the maxrow
	Local $iSplit = StringInStr($sString, $cLB, 1, $iMaxRow, 1)
	If @error Then Return SetError(3, @error)
	If $iSplit = 0 Then $iSplit = StringLen($sString)
	Local $sLeft = StringLeft($sString, $iSplit - 1)
	Local $sRight = StringTrimLeft($sString, $iSplit + StringLen($cLB) - 1)

	; split lines in the first half of the string
	Local $aAnfang = StringSplit($sLeft, $cLB, 1)

	Local $sRet = ""
	For $i = 1 To $aAnfang[0]
		If Not MapExists($mRows, $i)  Then
			$sRet &= $aAnfang[$i] & $cLB
		EndIf
	Next

	Return $sRight = "" ? StringTrimRight($sRet, StringLen($cLB)) : $sRet & $sRight
EndFunc

; helper function for automatic parsing
Func __td_parseAutomatic($sValue)
	Return StringRegExp($sValue, '(?i)\A(?|0x\d+|[-+]?(?>\d+)(?>\.\d+)?(?:e[-+]?\d+)?)\Z') ? _
		Number($sValue) : _
		IsString($sValue) ? _
			StringStripWS($sValue, 3) : _
			$sValue
EndFunc

; helper function for calling user-defined column definitions
Func __td_executeString($sCode, ByRef $x)
	Local $vRet = Execute($sCode)
	Return @error ? SetError(@error, 0, $vRet) : $vRet
EndFunc

#endregion helper functions