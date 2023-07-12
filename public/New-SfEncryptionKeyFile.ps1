Set-StrictMode -Version 3

function New-SfEncryptionKeyFile{
<# 
    .SYNOPSIS
    Creates a new encryption key file.

    .EXAMPLE
    PS>New-SfEncryptionKeyFile -Path MyKeyFile.key

    .LINK
    ConvertTo-SfEncryptedString
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>
[CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
	param (
		# Key file to create.
		[Parameter(Mandatory, Position=0)]
		[string]$Path,

        # If encryption key file of same name is already existing, keep it untouched.
        [Parameter()]
        [switch]$KeepExisting
	)

	# -------------------------------------------------------------- some ugly magic to get the common parameter debug
	$debug = $false
	if ( $PSBoundParameters.containskey(“debug”) ) {
		if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
			$DebugPreference = “Continue”
		}
	}
	Write-Debug "Debug-Mode: $debug"

	# -------------------------------------------------------------- actual logic
    if ($KeepExisting -and (Test-Path $Path)) {
        $s = "Keeps existing encryption key file <$Path>"
    } else {

        [string[]]$ArgumentList += '-k'
        $ArgumentList += $Path
        
        $s = InvokeSfDataloaderJavaClass -ClassName 'com.salesforce.dataloader.security.EncryptionUtil' -ArgumentList $ArgumentList
    }

	return $s
}

