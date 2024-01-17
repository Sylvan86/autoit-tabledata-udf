## Introduction

In AutoIt, we often have to deal with data structured like tables.
Depending on the source, we sometimes have to write a lot of code to convert the data into a form that we can continue working with.
Subsequently, working with this data is not necessarily any easier, as instead of accessing the descriptive names of the data attributes, we have to deal with numerical indices where it is very easy to lose track.

Both problems are addressed by the UDF.
In the basic approach, the UDF works with a table object (just an AutoIt map) in which the data is separated from the header.
This enables cleaner processing of the data.
It offers functions to read in data from various sources (CSV, array, string with fixed-width-columns, strings with their own column separators).
Within this call, the data is separated from the header or header data is added to it in the first place.
The data is then processed according to its format (with csv quotes and escapes removed, with fixed-width spaces removed...).
In addition, the user can define how exactly the data should be processed for each column individually. He is completely free to do this.
In this way, the data is already given the final format in which it is to be further processed when it is read in.

The data can then be handled on a column-based or attribute-based basis.
In other words, instead of using indices, the attribute names of the data can simply be used - this makes the code clearer.

## Example
We want to evaluate the open ports on a computer with AutoIt.
The command line command for this is `netstat -t` and gives us the following output:

```

Active Internet connections (w/o servers)

Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0    116 192.168.64.110:ssh      192.168.29.200:65069    ESTABLISHED
tcp        0      0 192.168.64.110:ssh      192.168.29.200:65068    ESTABLISHED
```
To continue processing the data in a meaningful way, we may need to carry out the following steps in AutoIt:

* Delete the first useless lines
* Extract the header row (it is treated differently from the data)
* Create an array with the correct dimension to hold the data
* Separate the data either by spaces or by fixed column widths
* Removal of unnecessary spaces from the data
* Converting the Recv-Q and Send-Q column to a numeric data type (for sorting etc.)
* Separation of address data into IP address and port

This can mean a lot of (error-prone) code effort.
With this UDF, however, you can solve the whole thing in a single call as follows:

```AutoIt
$sString = 'Active Internet connections (w/o servers)' & @CRLF & _
    '' & @CRLF & _
    'Proto Recv-Q Send-Q Local Address           Foreign Address         State' & @CRLF & _
    'tcp        0    116 192.168.64.110:ssh      192.168.29.200:65069    ESTABLISHED' & @CRLF & _
    'tcp        0      0 192.168.64.110:ssh      192.168.29.200:65068    ESTABLISHED'

; Transfer data to table type by using the size of every column:
Global $mData = _td_fromFixWidth($sString, _
                                 "left 6; Number 7; Number 7; StringSplit($x, ':', 2) 24;StringSplit($x, ':', 2) 24;", _ ; column definitions
                                 "1-2", _ ; skip row 1 to 2
								 True)

; display data
_td_display($mData)
```
and we get the result:
![Hello World]( data:image/png;base64,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)

If you now use functions such as `_td_TableToMaps()`, you can process the individual data with expressions such as `$aData.Proto` or `$aData.State`. This should be much clearer than having to deal with array indices.

## Functions
| function | description |
| -------- | ----------- |
| <b>input</b> | |
| `_td_fromString`      | convert table-structured strings where the column separator can be described by a regular expression into a table object |
|  `_td_fromCsv`         | read strings with 2D-array-like data from a string where the rows and columns separated by separator-chars (e.g.: csv or tsv) |
|  `_td_fromFixWidth`    | read 2D-array-like data from a string where the columns have a fixed width (e.g. console outputs or printf-strings) |
|  `_td_fromArray`       | creates a table object from an existing 2D array |
| <b>output</b> | |
|  `_td_toCsv`           | convert a table object into a csv formatted string |
|  `_td_toFixWidth`      | convert a table object into a string where the columns has fixed width` |
|  `_td_display`         | present a table object like _ArrayDisplay |
|  `_td_toArray`         | creates an array from a table object |
| <b>Preparation of 2D arrays</b> | <b>for easy further processing</b> |
|  `_td_TableToMaps`     | converts a 2D-Array (rows=records, columns=values, column headers=keys) into a set of key-value maps (every record = key-value map)
|  `_td_TableToDics`     | converts a 2D-Array (rows=records, columns=values, column headers=keys) into a set of objects (every record = Dictionary with named attributes) |
|  `_td_MapsToTable`    | converts a map-array (a 1D-array with maps as values) into 2 2D-array where the colums = keys |
|  `_td_toColumns`       | convert 2D-array or table-data map from this udf into a map with column names as keys and their data as 1D-arrays |
|  `_td_getColumn`      | extract one or multiple colums from a 2D-Array or a table-data map |