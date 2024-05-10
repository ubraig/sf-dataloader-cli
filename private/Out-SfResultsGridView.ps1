function Out-SfResultsGridView{
<# 
    .SYNOPSIS 
    

    .DESCRIPTION

    .LINK
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>

    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param(
        
        # Path/File name of the Excel workbook (.xlsx file)
        [Parameter(Mandatory)] 
        [hashtable]$DataloaderResultFiles

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

    # --- do it
    Import-Csv $DataloaderResultFiles.ErrorFile   | Out-GridView -Title 'ErrorFile'
    Import-Csv $DataloaderResultFiles.SuccessFile | Out-GridView -Title 'SuccessFile'
    Import-Csv $DataloaderResultFiles.SourceFile  | Out-GridView -Title 'SourceFile'

}

