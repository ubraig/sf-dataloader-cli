Set-StrictMode -Version 3

function ConvertTo-SfFieldList{
<# 
    .SYNOPSIS 
    Takes a list (array) of field names converts to a comma-separated list to be used in a SOQL statement.
    Fields with a comment prefix of '#' will be removed.

    .EXAMPLE
    PS>$MyContactFields = @('Id', '#FirstName', 'LastName', 'Account.Name', 'MyCustomField__c')
    PS>$MyFieldList = ConvertTo-SfFieldList $MyContactFields
    PS>$MySoqlSelect = "SELECT $MyFieldList FROM Contact"

    Will result to the following value in $MySoqlSelect:
    SELECT Id, LastName, Account.Name, MyCustomField__c FROM Contact

    .LINK
    Get-SfFieldNames
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki


#>
    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param (
        # List of field names as PowerShell string array, e.g. @('Id', 'FirstName', 'LastName').
        [Parameter(Mandatory, Position=0)]
        [string[]]$FieldNames
    )

    # -------------------------------------------------------------- some ugly magic to get the common parameter debug
    $debug = $false
    if ( $PSBoundParameters.containskey(“debug”) ) {
        if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
            $DebugPreference = “Continue”
        }
    }
    Write-Debug "Debug-Mode: $debug"

    # --- filter to remove thos prefixed with comment marker
    $NewFieldNames = $FieldNames.where( { $_ -NotLike '#*' })

    return $NewFieldNames -join ', '
}
