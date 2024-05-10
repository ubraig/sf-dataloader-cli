function ConvertFrom-SfExcelWorksheet{
<# 
    .SYNOPSIS 
    Converts a single worksheet of an Excel workbook into a .csv file ready to be used by DataLoader.
    Will return a string with the resulting .csv file name (full path).

    .DESCRIPTION
    The output file will have same name and path as the source file with the extension set to '.csv'.
    If parameter -AppendWorksheetName is given, the file name will be appended with the name of the worksheet.
    NOTE: Requires PowerShell-Module ImportExcel being installed.

    .EXAMPLE
    PS>ConvertFrom-SfExcelWorksheet .\MySourceFile.xlsx MyWorksheetName

    Creates .\MySourceFile.csv from the content of MyWorksheetName

    .EXAMPLE
    PS>ConvertFrom-SfExcelWorksheet .\MySourceFile.xlsx MyWorksheetName -AppendWorksheetName

    Creates .\MySourceFile-MyWorksheetName.csv from the content of MyWorksheetName

    .LINK
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>

    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param(
        
        # Path/File name of the Excel workbook (.xlsx file)
        [Parameter(Mandatory)] 
        [string]$SourceFile,

        # Name of the worksheet
        [Parameter()] 
        [string]$WorksheetName,

        # The file name of the output '.csv' file have the name of the worksheet appended.
        [Parameter()] 
        [switch]$AppendWorksheetName

    )

    #Requires -Version 5.1
    #Requires -Modules ImportExcel
    Set-StrictMode -Version 3

    # -------------------------------------------------------------- some ugly magic to get the common parameter debug
    $debug = $false
    if ( $PSBoundParameters.containskey(“debug”) ) {
        if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
            $DebugPreference = “Continue”
        }
    }
    Write-Debug "Debug-Mode: $debug"

    # --- prepare file names
    $ExcelFile = Get-Item $SourceFile
    if (!$WorksheetName) {
        Write-Debug "WorksheetName was NULL"
        $ExcelWorksheetInfos = Get-ExcelSheetInfo $ExcelFile
        $WorksheetName = $ExcelWorksheetInfos[0].Name
    }
    if ($AppendWorksheetName) {
        $CsvFileName = Join-Path $ExcelFile.Directory "$($ExcelFile.BaseName)-$WorksheetName.csv"
    } else {
        $CsvFileName = Join-Path $ExcelFile.Directory "$($ExcelFile.BaseName).csv"
    }

    Write-Verbose "Source Excel file: $($ExcelFile.FullName)"
    Write-Verbose "Target output file: $CsvFileName"

    # --- do it
    Import-Excel -Path $ExcelFile -WorksheetName $WorksheetName  | Export-Csv -Path $CsvFileName -Encoding UTF8 -NoTypeInformation

    # --- remove BOM from file (OLD)
    #$lines = Get-Content $CsvFileName
    #[IO.File]::WriteAllLines($CsvFileName, $lines)

    # --- remove BOM from the resulting file (NEW)
    # read but preserve (-Raw) the end-of-line character, i.e. return a single string (as apposed to a string array)
    $Content = Get-Content $CsvFileName -Raw

    # write without an additional EOL at the end (-NoNewLine)
    Set-Content $CsvFileName $Content -Encoding utf8NoBOM -NoNewLine

    return $CsvFileName
}

