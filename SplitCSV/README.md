# Split CSV
Filename: splitcsv.ps1
Split a large CSV into multiple smaller CSV files

### Parameters:
|Name	|	Required	|	Purpose |
| --- | --- | --- |
|SourceCSV	| true	|Path to the source CSV file|
|TargetFolder|	false	| Path to the folder where smaller files will be created. By default, folder path of given SourceCSV file is used.|
|RowsPerFile	|true	|Max rows to be split into a file|


### Usage Example:
Consider you have a large file (Name largefile.csv) with 10,000 rows that needs to be split into smaller files with 1000 rows in each file. Then, following command can help split it

> \> PS .\splitcsv -SourceCSV .\largefile.csv -RowsPerFile 1000
