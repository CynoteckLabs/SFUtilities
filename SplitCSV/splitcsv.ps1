# Parameters
param (
    [string]  $SourceCSV,               # Path to the source CSV file
    [string]  $TargetFolder,            # Path to the folder where smaller files will be created
    [int] $RowsPerFile                  # Max rows to be split into a file
)

$fileInfo = Get-Item $SourceCSV
$fileName = $fileInfo.Name

if($TargetFolder -eq ''){
    $TargetFolder = $fileInfo.Directory.FullName
}

$counter = 1
$startRow = 0

# Import the CSV file
$csvData = Import-Csv $SourceCSV

# Loop until all rows are processed
while ($startRow -lt $csvData.Count) {
    # Select a chunk of rows
    $chunk = $csvData | Select-Object -Skip $startRow -First $RowsPerFile
	
	# Export the chunk to a new CSV file
    $outputFile = Join-Path $TargetFolder ($filename + "_$counter.csv")
    $chunk | Export-Csv -Path $outputFile -NoTypeInformation

    # Increment counters
    $startRow += $RowsPerFile
    $counter++
}

$counter = $counter - 1

echo "Total files created : $counter"