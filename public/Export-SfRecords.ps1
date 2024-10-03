Set-StrictMode -Version 3

function Export-SfRecords{
<# 
    .SYNOPSIS 
    Invokes Salesforce Data Loader for a QUERY (EXTRACT) operation that exports data to a .csv file.

    .DESCRIPTION
    Executes the SOQL SELECT statement as provided and writes the result to a .csv file.
    
    The format of the .csv file is defined as: UTF-8 encoding, without BOM, comma (,) as separator.
    For more details see https://github.com/ubraig/sf-dataloader-cli/wiki/about-csv-files

    .EXAMPLE
    PS>$MyOrg = Get-SfAuthToken -BrowserLogin Sandbox
    PS>Export-SfRecords $MyOrg Lead "SELECT Id, FirstName, LastName, Company FROM Lead" MyLeads.csv

    Will open a browser window that asks to confirm the code and then asks for user name + password.
    Then exports Lead records to the MyLeads.csv file.

    .LINK
    Get-SfAuthToken
    Online version: https://github.com/ubraig/sf-dataloader-cli/wiki

#>
    [CmdletBinding(HelpURI="https://github.com/ubraig/sf-dataloader-cli/wiki")]
    param (
        # Hashmap as provided by Get-SfAuthToken command.
        [Parameter(Mandatory, Position=0)]
        [hashtable]$SfAuthToken,

        # API name of the sObject/entity.
        [Parameter(Mandatory, Position = 1)]
        [string]$Object,

        # A complete SOQL statement.
        # If no SELECT statement is given, it will default to "SELECT Id FROM <Object>".
        # The SELECT statement may include WHERE, ORDER BY and LIMIT clauses.
        [Parameter(Position=2)]
        [string]$Soql = "SELECT Id FROM $Object",

        # Path and filename of the output csv file. Needs to include the '.csv' extension.
        [Parameter(Position=3)]
        [string]$Path = "$Object.csv",

        [Parameter()]
        [switch]$ExtractAll,
        
        # 'Serial'   : Use BULK API in serial mode.
        # 'Parallel' : Use BULK API in parallel mode.
        # Default if not given is SOAP API.
        [Parameter()]
        [ValidateSet('Serial', 'Parallel')]
        [string]$Bulk,

        # Default used for SOAP API: 200.
        # Default used for BULK API: 2000.
        [Parameter()]
        [int32]$BatchSize = (&{ if ($bulk) { 2000 } else { 200 } }),

        # Shows the result files in the given format.
        #   'Default'  : Open .csv with the default application for .csv files.
        #   'Excel'    : Convert to .xlsx file and open with Excel.
        #   'GridView' : Opens .csv result file with the Out-GridView command.
        [Parameter()]
        [ValidateSet('Default', 'GridView', 'Excel')]
        [string]$ShowAs

    )

    # -------------------------------------------------------------- some ugly magic to get the common parameter debug
    $debug = $false
     if ( $PSBoundParameters.containskey(“debug”) ) {
        if ( $debug = [bool]$PSBoundParameters.item(“debug”) ) { 
            $DebugPreference = “Continue”
        }
    }
    Write-Debug "Debug-Mode: $debug"
    Write-Verbose "ParameterSetName: $($PSCmdlet.ParameterSetName)"

    # --------------------------------------- Start Working
    $ProcessName = "$($MyInvocation.MyCommand.Name)-$Object"
    $ConfigTempDir = InitializeConfigTempDir
    Set-Content $Path ''
    $Path = (Resolve-Path $Path).Path

    # --------------------------------------- Prepare log-conf.xml
    $s = BuildDataloaderLogConfXml $ConfigTempDir "$ConfigTempDir/$ProcessName"
    Write-Verbose "Created: <$s>"

    # --------------------------------------- Prepare config.properties
    $item = Copy-Item "$PSScriptRoot\..\configs\config.properties" $ConfigTempDir -PassThru
    $s = $item.FullName
    Write-Verbose "Created: <$s>"

    # --------------------------------------- Build Config Override Map
    $ConfigOverrideMap = $SfAuthToken
    $ConfigOverrideMap += BuildBulkModeConfigMap $Bulk
    # -- in case someone has set process.enableExtractStatusOutput=false we define error/success file paths here even if not used
    $ConfigOverrideMap += BuildErrorSuccessFileNames $Path
    $ConfigOverrideMap += @{
        'sfdc.extractionRequestSize' = $BatchSize
        'sfdc.entity' = $Object
        'sfdc.extractionSOQL' = [System.Security.SecurityElement]::Escape($soql)
        'dataAccess.type' = 'csvWrite'
        'dataAccess.name' = $Path
        'process.operation' = (&{ if ($ExtractAll) { 'extractAll' } else { 'extract' }})
    }

    # --------------------------------------- Build the process-conf.xml
    $ProcessConfXmlFilename = "$ConfigTempDir\process-conf.xml"
    [xml]$ProcessConfXmlDocument = BuildDataloaderProcessConfXml $ProcessName $ConfigOverrideMap
	$ProcessConfXmlDocument.Save($ProcessConfXmlFilename) 
	Write-Verbose "Created: <$ProcessConfXmlFilename>"

    if ($debug) {
        $ConfigOverrideMap | Out-GridView
    }
    
    # --------------------------------------- Invoke dataloader
    [string[]]$SystemPropertiesList = @(
        "-Dsalesforce.config.dir=$ConfigTempDir"
    )
    [string[]]$ArgumentList = @(
        $ConfigTempDir,
        $ProcessName,
        'run.mode=batch'
    )
    $s = InvokeSfDataloaderJavaClass -SystemPropertiesList $SystemPropertiesList -ClassName 'com.salesforce.dataloader.process.DataLoaderRunner' -ArgumentList $ArgumentList

    if ($ShowAs) {
        Show-SfResults $Path $ShowAs
    }


    return $Path
}
