Set-StrictMode -Version 3

function Remove-SfRecords {
<# 
    .SYNOPSIS 
    Invokes Salesforce Data Loader with an DELETE or HARD_DELETE operation to delete records as given in a .csv file.

    .LINK
    Get-SfAuthToken
    ConvertTo-SfMappingFile
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
        
        # Path and filename of the input .csv file. 
        # Needs to include the '.csv' extension.
        # If no file name is provided, it will look for the default name "<Object>.csv" in the current directory.
        [Parameter(Position = 2)]
        [string]$Path = "$Object.csv",

        # Path and filename of the '.sdl' mapping file. 
        # If empty, a default mapping file will be created on the fly based on the column names in the input .csv file.
        [Parameter()]
        [string]$MappingFile,

        # 'Serial'            : Use BULK API in serial mode.
        # 'Parallel'          : Use BULK API in parallel mode.
        # 'SerialHardDelete'  : Use BULK API for a HARD_DELETE operation in serial mode.
        # 'ParallelHardDelete': Use BULK API for a HARD_DELETE operation in parallel mode.
        # Default if not given is SOAP API.
        [Parameter()]
        [ValidateSet('Serial', 'Parallel', 'SerialHardDelete', 'ParallelHardDelete')]
        [string]$Bulk,

        # Default used for SOAP API: 200.
        # Default used for BULK API: 2000.
        [Parameter()]
        [int32]$BatchSize = (&{ if ($bulk) { 2000 } else { 200 } })
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

    # --------------------------------------- Start Working
    $ProcessName = "$($MyInvocation.MyCommand.Name)-$Object"
    $ConfigTempDir = InitializeConfigTempDir

    # --------------------------------------- Prepare log-conf.xml
    $s = BuildDataloaderLogConfXml $ConfigTempDir (Join-Path $ConfigTempDir $ProcessName)
    Write-Verbose "Created: <$s>"

    # --------------------------------------- Prepare config.properties
    $item = Copy-Item "$PSScriptRoot\..\configs\config.properties" $ConfigTempDir -PassThru
    $s = $item.FullName
    Write-Verbose "Created: <$s>"

    # --------------------------------------- Check for mapping file. If necessary, build a default mapping
    if (!$MappingFile) {
        $MappingFile = ConvertTo-SfMappingFile @('Id') ($Path.Replace('.csv', '.sdl'))
    }

    # --------------------------------------- Process parameters
    $Path = Resolve-Path $Path

    # --------------------------------------- Build Config Override Map
    $ConfigOverrideMap = $SfAuthToken
    $ConfigOverrideMap += BuildBulkModeConfigMap $Bulk
    $ConfigOverrideMap += BuildErrorSuccessFileNames $Path
    $ConfigOverrideMap += @{
        'sfdc.loadBatchSize'    = $BatchSize
        'sfdc.entity'           = $Object
        'dataAccess.type'       = 'csvRead'
        'dataAccess.name'       = $Path
        'process.mappingFile'   = $MappingFile
        'process.operation'     = (&{ if ($Bulk.EndsWith('HardDelete')) { 'hard_delete' } else { 'delete' } })
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

    return @{
        SourceFile  = Resolve-Path $Path
        ErrorFile   = Resolve-Path $ConfigOverrideMap.'process.outputError'
        SuccessFile = Resolve-Path $ConfigOverrideMap.'process.outputSuccess'
        MappingFile = Resolve-Path $MappingFile
    }
}
