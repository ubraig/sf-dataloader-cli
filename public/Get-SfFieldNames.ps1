Set-StrictMode -Version 3

function Get-SfFieldNames{
<# 
    .SYNOPSIS 
    Collects a list of field names from various source file formats and returns as a list (array) of field names.

    .LINK
    ConvertTo-SfFieldList
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>
    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param (
        # Source file to extract field names from.
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        # Name of the converter to be applied in order to get the field name list.
        # If none is given, the file extension is used.
        #	txt
        #		A plain text file with a field name in each line.
        #		Lines starting with '#' will be ignored.
        #	csv
        #		First line in the file will be interpreted as column names.
        #		Column names starting with '#' will be ignored.
        #	sdl
        #		A dataloader mapping file (.sdl) with a dataloader mapping entry on each line.
        #		The part left of the '=' will be used as field name.
        #		Lines without a '=' will be ignored.
        #		Lines starting with '#' will be ignored.
        #	sdlRightSide
        #		A dataloader mapping file (.sdl) with a dataloader mapping entry on each line.
        #		The part right of the '=' will be used as field name.
        #		Lines without a '=' will be ignored.
        #		Lines starting with '#' will be ignored.
        [Parameter(Position = 1)]
        [ValidateSet('txt', 'csv', 'sdl', 'sdlRightSide')]
        [string]$Converter = (((Get-Item $Path ).Extension) -replace '\.', '')

    )

    # -------------------------------------------------------------- some ugly magic to get the common parameter debug
    $debug = $false
    if ( $PSBoundParameters.containskey(“debug”) ) {
        if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
            $DebugPreference = “Continue”
        }
    }
    Write-Debug "Debug-Mode: $debug"
    Write-Debug "Name of Converter:  $Converter"

    # --------------------------------------- Debug Output
    [string[]]$Fields = @()
    switch ($Converter) {
        'txt' { 
            [string[]]$Lines = Get-Content $Path
            foreach ($Line in $Lines) {
                if (!($Line.startswith('#'))) {
                    $Fields += $Line
                }
            }
        }
        'csv' {
            # get the first line = the line with the column names. Split at the comma and remove double quotes.
            [string[]]$CsvColumns = (Get-Content -Path .\temp.csv -TotalCount 1) -split ',' -replace '"', ''
            foreach ($CsvColumn in $CsvColumns) {
                if (!($CsvColumn.startswith('#'))) {
                    $Fields += $CsvColumn
                }
            }
        }
        'sdl' {
            [string[]]$Lines = Get-Content $Path
            foreach ($Line in $Lines) {
                $Mapping = $Line.Split('#')[0].Trim()  # ignore comments starting with first occurence of a hash
                if ($Mapping -ne '') {
                    $Fields += $Mapping.Split('=')[0].Trim()
                }
            }
        }
        'sdlRightSide' {
            [string[]]$Lines = Get-Content $Path
            foreach ($Line in $Lines) {
                $Mapping = $Line.Split('#')[0].Trim()  # ignore comments starting with first occurence of a hash
                if ($Mapping -ne '') {
                    $Fields += $Mapping.Split('=')[1].Trim().Replace('\:', '.')
                }
            }
        }
        default { 
            $Fields += 'Id'
        }
    }
    return $Fields 
}
