function ConvertFrom-SfExcelWorkbook{
<# 
    .SYNOPSIS 
    Converts one, multiple or all worksheet of an Excel workbook into separate .csv files ready to be used by DataLoader.
    Will return a string array with the resulting .csv file names (full path).

    .DESCRIPTION
    The output file will have same name and path as the source file with the extension set to '.csv'.
    The file name will be appended with the name of the worksheet.
    NOTE: Requires PowerShell-Module ImportExcel being installed.

    .EXAMPLE
    PS>ConvertFrom-SfExcelWorkbook .\MySourceFile.xlsx 

    Assume, the .xlsx file has got 3 worksheets: WorksheetA, WorksheetB and WorksheetC
    The command will convert all of those into 3 separate .csv files: 
        .\MySourceFile-WorksheetA.csv
        .\MySourceFile-WorksheetB.csv
        .\MySourceFile-WorksheetC.csv

    .EXAMPLE
    PS>ConvertFrom-SfExcelWorkbook .\MySourceFile.xlsx MyWorksheetA, MyWorksheetB

    Assume, the .xlsx file has got 3 worksheets: WorksheetA, WorksheetB and WorksheetC
    The command will convert the given 2 worksheets into 2 separate .csv files: 
        .\MySourceFile-WorksheetA.csv
        .\MySourceFile-WorksheetB.csv

    .LINK
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>

    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param(
        
        # Path/File name of the Excel workbook (.xlsx file)
        [Parameter(Mandatory)] 
        [string]$SourceFile,

        # Name of the worksheet(s). If empty, will iterate through all visible worksheets of the workbook.
        [Parameter()] 
        [string[]]$WorksheetNames
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
    Write-Verbose "Source Excel file: $($ExcelFile.FullName)"

    $ResultingFileNames = @()
    $ExcelWorksheetInfos = Get-ExcelSheetInfo $ExcelFile
    if ($debug) {
        Write-Host $ExcelWorksheetInfos
        pause
    }
    foreach ($ExcelWorksheetInfo in $ExcelWorksheetInfos) {
        if ( ((!$WorksheetNames) -or ($ExcelWorksheetInfo.Name -in $WorksheetNames)) -and ($ExcelWorksheetInfo.Hidden -eq 'Visible') ) {
            Write-Verbose "Processing Worksheet [$($ExcelWorksheetInfo.Name)]"
            $ResultingFileNames += ConvertFrom-SfExcelWorksheet $ExcelFile $ExcelWorksheetInfo.Name -AppendWorksheetName
        } else {
            Write-Verbose "Skipped Worksheet [$($ExcelWorksheetInfo.Name)]"
        }
    }

    Write-Host "Target output files: $ResultingFileNames"

    return $ResultingFileNames
}

