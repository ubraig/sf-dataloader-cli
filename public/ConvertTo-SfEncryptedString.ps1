Set-StrictMode -Version 3
function ConvertTo-SfEncryptedString{
<# 
    .SYNOPSIS 
    Encrypts a string (either provided via command line parameter or prompted via console input) based on the key file provided.

    .EXAMPLE
    PS>New-SfEncryptionKeyFile -Path MyKeyFile.key
    PS>ConvertTo-SfEncryptedString -KeyFile MyKeyFile.key -StringToEncrypt 'MyUnencryptedPassword'

    Will return the encrypted password to the console. This string then can be safely stored in scripts in order
    to be used as parameter -EncryptedString in command Get-SfAuthToken.

    .EXAMPLE
    PS>New-SfEncryptionKeyFile -Path MyKeyFile.key
    PS>ConvertTo-SfEncryptedString -KeyFile MyKeyFile.key -Prompt 'Enter password + security token'

    Will prompt the user for secure console input, i.e. string entered will not show up on the screen.
    Will return the encrypted password string to the console. This string then can be safely stored in scripts in order
    to be used as parameter -EncryptedString in command Get-SfAuthToken.

    .EXAMPLE
    PS>New-SfEncryptionKeyFile -Path MyKeyFile.key
    PS>$MyEncryptedPassword = ConvertTo-SfEncryptedString -KeyFile MyKeyFile.key -Prompt 'Enter password + security token'
    PS>$MyOrg = Get-SfAuthToken MyUserName@MyOrg.de -EncryptedString $MyEncryptedPassword -InstanceUrl https://test.salesforce.com -KeyFile .\MyKeyFile.key

    Will prompt the user for secure console input, i.e. string entered will not show up on the screen.
    Will then create an Auth token from it for the given user in the Sandbox.

    .LINK
    New-SfEncryptionKeyFile
    Get-SfAuthToken
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>
[CmdletBinding(DefaultParameterSetName = 'string_from_secure_input', HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
	param (
        # Path to the key file. The file must already exist.
		[Parameter(Position = 0, Mandatory)]
        [string]$KeyFile,

        # String that is to be encrypted.
        # If empty, user will be prompted for console input.
		[Parameter(ParameterSetName = 'string_from_commandline', Mandatory)]
        [string]$StringToEncrypt,

        # Prompt for secure input. If not provided, a default prompt will be used.
        [Parameter(ParameterSetName = 'string_from_secure_input')]
        [string]$Prompt = 'Enter string to encrypt'

    )

	# -------------------------------------------------------------- some ugly magic to get the common parameter debug
	$debug = $false
	if ( $PSBoundParameters.containskey(“debug”) ) {
		if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
			$DebugPreference = “Continue”
		}
	}
	Write-Debug "Debug-Mode: $debug"
    Write-Debug "ParameterSetName: $($PSCmdlet.ParameterSetName)"

    # --- secure input
    if ($PSCmdlet.ParameterSetName -eq 'string_from_secure_input') {
        $SecureString = Read-Host $Prompt -AsSecureString
        $StringToEncrypt = ([System.Net.NetworkCredential]::new("", $SecureString).Password)
    }

	# -------------------------------------------------------------- actual logic
	$ClassName = 'com.salesforce.dataloader.security.EncryptionUtil'
	[string[]]$ArgumentList = '-e', $StringToEncrypt, $KeyFile
	
	$s = InvokeSfDataloaderJavaClass -ClassName $ClassName -ArgumentList $ArgumentList
	Write-Debug $s
	
	# --- Parse out the actual encryption result
	$EncryptedString = $s + ':'
	$EncryptedString = $EncryptedString.Split(':')[1].Trim()  
	
    return $EncryptedString
}

<# 
    #Start-Process -NoNewWindow -wait -FilePath "$JavaHome\bin\java" -ArgumentList $ArgumentList
    $EncryptedOutput = & $JavaHome\bin\java -cp $ClassPath com.salesforce.dataloader.security.EncryptionUtil -e $Password$SecurityToken $KeyFile
    [string]$s = $EncryptedOutput
    $s += ':'
    $s = $s.Split(':')[1].Trim()
    return $s
 #>