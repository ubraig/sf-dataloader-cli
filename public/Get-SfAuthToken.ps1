Set-StrictMode -Version 3

function Get-SfAuthToken{
<# 
    .SYNOPSIS 
    Offers various options to authorize an Org in order to get an AuthToken suitable for Data Loader.

    .DESCRIPTION
    Each command that calls Data Loader requires an AuthToken as the first parameter.
    Technically, the token is a HashTable with name/value pairs ready to be used in the ConfigMap in Data Loader.
    If SFDX is installed, the authorizations from SFDX can be used.

    .EXAMPLE
    PS>$MyOrg = Get-SfAuthToken

    Uses the oauth token of the default org as set in SFDX.
    See 'sfdx org display' command.

    .EXAMPLE
    PS>$MyOrg = Get-SfAuthToken MySfdxOrgAlias

    Uses the oauth token of the  org 'MySfdxOrgAlias' as set in SFDX.
    See 'sfdx auth list' command for more details.

    .EXAMPLE
    PS>$MyOrg = Get-SfAuthToken MyUserName@MyOrg.de -ConsoleInput -InstanceUrl https://test.salesforce.com

    Will ask for the password via secure input and prepare credential for sandbox URL.

    .EXAMPLE
    PS>$MyOrg = Get-SfAuthToken MyUserName@MyOrg.de -EncryptedString 'MyEncryptedPwdAndSecToken' -InstanceUrl https://test.salesforce.com -KeyFile .\MyKeyFile.key

    Take the password (and security token) that has already been encrypted with MyKeyFile.key and prepare credential for sandbox URL.
    See New-SfEncryptionKeyFile and ConvertTo-SfEncryptedString for more details.

    .EXAMPLE
    PS>$MyOrg = -BrowserLogin Sandbox
    
    Will create a placeholder token.
    Each time it is used for calling Data Loader, a browser window will open and ask for username/password.

    .LINK
    New-SfEncryptionKeyFile
    ConvertTo-SfEncryptedString
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>
    [CmdletBinding(DefaultParameterSetName = 'sfdx', HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param (
        # SFDX OrgAlias or Username.
        # If empty, the SFDX default setting will be used.
        [Parameter(Position = 0, ParameterSetName = 'sfdx')]
        [Alias('o')]
        [string]$OrgAliasOrUsername,

        # Salesforce Username
        [Parameter(Position = 0, ParameterSetName = 'password_from_encrypted_string', Mandatory)]
        [Parameter(Position = 0, ParameterSetName = 'password_from_secure_input', Mandatory)]
        [string]$Username,

        # Encrypted password + security token.
        [Parameter(Position = 1,ParameterSetName = 'password_from_encrypted_string', Mandatory)]
        [string]$EncryptedString,

        # Ask password and, if necessary, security token securely from user.
        [Parameter(ParameterSetName = 'password_from_secure_input', Mandatory)]
        [switch]$ConsoleInput,

        # Path to an existing key file that is to be used.
        # If empty, a default key file will be generated and used.
        # If the default key file already exists, it will be re-used.
        # Mandatory in case an encrypted password is given.
        [Parameter(ParameterSetName = 'password_from_encrypted_string', Mandatory)]
        [Parameter(ParameterSetName = 'password_from_secure_input')]
        [Parameter(ParameterSetName = 'sfdx')]
        [string]$KeyFile,

        # Open a Browser window to enter username and password. Need to provide type of environment: Sandbox | Production
        [Parameter(ParameterSetName = 'browser_login', Mandatory)]
        [ValidateSet('Production', 'Sandbox')]
        [string]$BrowserLogin,

        # Instance URL of the Org, e.g.
        # - https://test.salesforce.com for sandbox 
        # - https://login.salesforce.com for production, or
        # - the MyDomain URL.
        [Parameter(ParameterSetName = 'password_from_encrypted_string', Mandatory)]
        [Parameter(ParameterSetName = 'password_from_secure_input', Mandatory)]
        [string]$InstanceUrl # = 'https://test.salesforce.com'

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
    if ($debug) {
        pause
    }

    # --------------------------------------- Working Dir
    $ConfigTempDir = InitializeConfigTempDir

    # --------------------------------------- Prepare key file
    if (!$KeyFile) {
        $KeyFile = Join-Path $ConfigTempDir 'SfDataloader.key'
        if (!(Test-Path $KeyFile)) {
            $s = New-SfEncryptionKeyFile $KeyFile 
            Write-Verbose "Created: <$s>"
        } else {
            Write-Verbose "Reusing existing key file: <$KeyFile>"
        }
    }

    switch ($PSCmdlet.ParameterSetName) {

        'sfdx' {
            # --------------------------------------- Process username/alias
            if (!$OrgAliasOrUsername) {
                $jo = sfdx force:org:display --json | ConvertFrom-Json
            } else {
                $jo = sfdx force:org:display -u $OrgAliasOrUsername --json | ConvertFrom-Json
            }

            # --------------------------------------- Encryption magic
            $EncryptedAccessToken = ConvertTo-SfEncryptedString $KeyFile -StringToEncrypt $jo.result.accessToken

            # --------------------------------------- Build Config Override Map
            $ConfigOverrideMap = @{
                'sfdc.endpoint' = $jo.result.instanceUrl
                'sfdc.username' = $jo.result.username
                'sfdc.oauth.loginfrombrowser' = 'false'  # enforce using the oauth.accesstoken as given in the next line
                'sfdc.oauth.accesstoken' = $EncryptedAccessToken
                'process.encryptionKeyFile' = $KeyFile
            }
        }

        'password_from_secure_input' {
            # --------------------------------------- Password and encryption magic
            #$SecurePassword = Read-Host 'Enter password and, if applicable, security token' -AsSecureString
            #$EncryptedString = ConvertTo-SfEncryptedString $KeyFile ([System.Net.NetworkCredential]::new("", $SecurePassword).Password)

            $EncryptedString = ConvertTo-SfEncryptedString $KeyFile -Prompt 'Enter password and, if applicable, security token'
            # --------------------------------------- Build Config Override Map
            $ConfigOverrideMap = @{
                'sfdc.endpoint' = $InstanceUrl
                'sfdc.username' = $Username
                'sfdc.password' = $EncryptedString
                'process.encryptionKeyFile' = $KeyFile
            }
        }

        'password_from_encrypted_string' {
            # --------------------------------------- Build Config Override Map
            $ConfigOverrideMap = @{
                'sfdc.endpoint' = $InstanceUrl
                'sfdc.username' = $Username
                'sfdc.password' = $EncryptedString
                'process.encryptionKeyFile' = $KeyFile
            }
        }

        'browser_login' {
            # --------------------------------------- Build Config Override Map
            $ConfigOverrideMap = @{
                #'sfdc.oauth.server' = $InstanceUrl
                #'sfdc.oauth.environment' = $Environment
                'sfdc.oauth.environment' = $BrowserLogin
                'sfdc.username' = 'dummy@invalid.com'
                'sfdc.oauth.loginfrombrowser' = 'true'  # enforce using the oauth.accesstoken as given in the next line
            }
        }

    }

    Write-Debug $ConfigOverrideMap
    return $ConfigOverrideMap
}
