Set-StrictMode -Version 3

function Update-SfRecords {
<# 
    .SYNOPSIS 
    Invokes Salesforce Data Loader with an UPDATE operation to create/update records from a '.csv' or a '.xlsx' file.

    .DESCRIPTION
    Reads records from a .csv file and UPDATEs those in the org that is represented by the AuthToken.
    The primary key always is the Record ID that needs to be provided in the .csv file.

    If no filename is given, it is derived from the object to be imported: "<Object>.csv".
    The format of the .csv file is defined as: UTF-8 encoding, without BOM, comma (,) as separator.
    For more details see https://github.com/ubraig/sf-dataloader-cli/wiki/about-csv-files

    If no mapping file ist given, a default mapping file will be derived from the column headers in the .csv file. 
    See ConvertTo-SfMappingFile for details on this behaviour.

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
        # Needs to include either the '.csv' or the '.xlsx' extension.
        # If no file name is provided, it will look for the default name "<Object>.csv" in the current directory.
        [Parameter(Position = 2)]
        [string]$Path = "$Object.csv",

        # Name of the worksheet in case an Excel file with '.xlsx' extension is given as in -Path parameter
        # If an '.xlsx' file is given but -WorksheetName is empty, the first worksheet will be used.
        [Parameter(Position=4)]
        [string]$WorksheetName,

        # Path and filename of the '.sdl' mapping file. 
        # If empty, a default mapping file will be created on the fly based on the column names in the input .csv file.
        [Parameter()]
        [string]$MappingFile,

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

        # Sets the value of 'sfdc.insertNulls' to 'false'. (Default of this package is 'true'.)
        [Parameter()]
        [switch]$NoInsertNulls,

        # Shows the result files in the given format.
        #   'Default'  : Open .csv with the default application for .csv files.
        #   'Excel'    : Convert to .xlsx file and open with Excel.
        #   'GridView' : Opens .csv result file with the Out-GridView command.
        [Parameter()]
        [ValidateSet('Default', 'GridView', 'Excel')]
        [string]$ShowAs

        # # Convert the SUCCESS and ERROR files to Excel after processing, each in a separate Worksheet
        # [Parameter()]
        # [switch]$ConvertToExcel,

        # # Show the result files after finishing.
        # # If -ConvertToExcel is set, will open the resulting .xlsx file via Excel.
        # # If not, will pippe the .csv files to the screen wie Out-GridView
        # [Parameter()]
        # [switch]$Show
        
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

    # --------------------------------------- Prepare Source File
    $Path = (Resolve-Path $Path).Path
    if ($Path.EndsWith('.xlsx')) {
        $Path = ConvertFrom-SfExcelWorksheet $Path $WorksheetName -AppendWorksheetName
    }
    $SourceFile = Get-ChildItem $Path

    # --------------------------------------- Check for mapping file. If necessary, build a default mapping
    if (!$MappingFile) {
        $MappingFile = Join-Path $SourceFile.Directory "$($SourceFile.BaseName).sdl"
        $MappingFile = ConvertTo-SfMappingFile (Get-SfFieldNames $Path) $MappingFile
    }

    # --------------------------------------- Build Config Override Map
    $ConfigOverrideMap = $SfAuthToken
    $ConfigOverrideMap += BuildBulkModeConfigMap $Bulk
    $ConfigOverrideMap += BuildErrorSuccessFileNames $Path
    $ConfigOverrideMap += @{
        'sfdc.loadBatchSize'    = $BatchSize
        'sfdc.entity'           = $Object
        'sfdc.insertNulls'      = { if ($NoInsertNulls) { 'false' } else { 'true' } }
        'dataAccess.type'       = 'csvRead'
        'dataAccess.name'       = $Path
        'process.mappingFile'   = $MappingFile
        'process.operation'     = 'update'
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

    # --- prepare return values
    $DataloaderResultFiles = @{
        SourceFile  = (Resolve-Path $Path).Path
        ErrorFile   = (Resolve-Path $ConfigOverrideMap.'process.outputError').Path
        SuccessFile = (Resolve-Path $ConfigOverrideMap.'process.outputSuccess').Path
        MappingFile = (Resolve-Path $MappingFile).Path
    }

    if ($ShowAs) {
        Show-SfResults $DataloaderResultFiles $ShowAs
    }

    return $DataloaderResultFiles
}
