function ConvertTo-SfResultsExcelWorkbook{
<# 
    .SYNOPSIS 
    Converts one or multiple .csv files to one or many worksheets in an Excel workbook.

    .DESCRIPTION
    NOTE: Requires PowerShell-Module ImportExcel being installed.

    .LINK
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>

    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param(
        
        # Path/File name of the Excel workbook (.xlsx file)
        #[Parameter(Mandatory)] 
        #[hashtable]$DataloaderResultFiles

        #
        [Parameter(Mandatory)] 
        [string]$TargetPath,

        # Ordered dictionary with Worksheet
        [Parameter(Mandatory)] 
        [System.Collections.Specialized.OrderedDictionary]$Worksheets

    )

    #Requires -Version 5.1
    #Requires -Modules ImportExcel
    Set-StrictMode -Version 3

    function ExportCsv([string]$TargetPath, $CsvFileName, [string]$Name) {
        $Parameters = @{
            InputObject         = (Import-Csv $CsvFileName)
            Path                = $TargetPath
            ClearSheet          = $true
            FreezeTopRow        = $true
            AutoSize            = $true
            NoNumberConversion  = '*'
            TableStyle          = 'Medium2'
            TableName           = $Name
            WorksheetName       = $Name
        }
        Export-Excel @Parameters
    }


    # -------------------------------------------------------------- some ugly magic to get the common parameter debug
    $debug = $false
    if ( $PSBoundParameters.containskey(“debug”) ) {
        if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
            $DebugPreference = “Continue”
        }
    }
    Write-Debug "Debug-Mode: $debug"

    # --- do it
    # $SourceFile = Get-Item $DataloaderResultFiles.SourceFile
    # $XlsResultsFileName = Join-Path $SourceFile.Directory "$($SourceFile.BaseName)-RESULTS.xlsx"

    # ExportCsv $XlsResultsFileName $DataloaderResultFiles.ErrorFile    'ErrorFile'
    # ExportCsv $XlsResultsFileName $DataloaderResultFiles.SuccessFile  'SuccessFile'
    # ExportCsv $XlsResultsFileName $DataloaderResultFiles.SourceFile   'SourceFile'

    if (Test-Path $TargetPath) {
        Remove-Item $TargetPath
    }

    foreach ($w in $Worksheets.GetEnumerator()) {
        ExportCsv $TargetPath $w.Value $w.Name
    }

    return $TargetPath
}

