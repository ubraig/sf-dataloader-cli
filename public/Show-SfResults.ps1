function Show-SfResults{
<# 
    .SYNOPSIS 
    Takes the dataloader result file names and shows them to the user in the chosen format.

    .DESCRIPTION

    .LINK
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>

    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param(
        
        # Path/File name of the Excel workbook (.xlsx file)
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'set_of_files')] 
        [hashtable]$ResultFiles,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'single_file')] 
        [string]$ResultFile,

        # Shows the result files in the given format.
        #   'Default'  : Open .csv with the default application for .csv files.
        #   'Excel'    : Convert to .xlsx file and open with Excel.
        #   'GridView' : Opens .csv result file with the Out-GridView command.
        [Parameter(Position = 1)]
        [ValidateSet('Default', 'GridView', 'Excel')]
        [string]$ShowAs = 'Default'

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



    # -------------------------------------------------------------- show
    switch ($PSCmdlet.ParameterSetName) {
        
        'single_file' {

            switch ($ShowAs) {

                'Default' {
                    Invoke-Item $ResultFile
                }
        
                'GridView' {
                    Import-Csv $ResultFile   | Out-GridView -Title 'Result File'
                }
        
                'Excel' {
                    $SourceFile = Get-Item $ResultFile
                    $TargetPath = Join-Path $SourceFile.Directory "$($SourceFile.BaseName)-RESULTS.xlsx"
                    $Worksheets = [ordered]@{
                        'ResultFile' = $ResultFile
                    }
                    $XlsResultsFileName = ConvertTo-SfResultsExcelWorkbook $TargetPath $Worksheets
                    Invoke-Item $XlsResultsFileName
                }
            }

        }

        'set_of_files' {

            switch ($ShowAs) {

                'Default' {
                    Invoke-Item $ResultFiles.ErrorFile
                    Invoke-Item $ResultFiles.SuccessFile
                    Invoke-Item $ResultFiles.SourceFile
                }
        
                'GridView' {
                    Import-Csv $ResultFiles.ErrorFile   | Out-GridView -Title 'Error File'
                    Import-Csv $ResultFiles.SuccessFile | Out-GridView -Title 'Success File'
                    Import-Csv $ResultFiles.SourceFile  | Out-GridView -Title 'Source File'
                }
        
                'Excel' {
                    $SourceFile = Get-Item $ResultFiles.SourceFile
                    $TargetPath = Join-Path $SourceFile.Directory "$($SourceFile.BaseName)-RESULTS.xlsx"

                    $Worksheets = [ordered]@{
                        'ErrorFile'   = $ResultFiles.ErrorFile
                        'SuccessFile' = $ResultFiles.SuccessFile
                        'SourceFile'  = $ResultFiles.SourceFile
                    }

                    $XlsResultsFileName = ConvertTo-SfResultsExcelWorkbook $TargetPath $Worksheets
                    Invoke-Item $XlsResultsFileName
                }
            }
        
        }

    }

}

