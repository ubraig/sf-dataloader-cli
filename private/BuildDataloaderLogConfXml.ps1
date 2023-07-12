Set-StrictMode -Version 3

function BuildDataloaderLogConfXml{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$ConfigFilesPath,
        [Parameter(Mandatory)][string]$LogFilePath
    )

    # ------------------------------------ load the template
    [string[]]$LogConfTemplateLines = Get-Content -Path "$PSScriptRoot\..\configs\log-conf.xml"

    # ------------------------------------ patch the template
    $LogFilePath = $LogFilePath -replace '\\', '/'
    [string[]]$LogConfXmlLines = @()   # empty array to collect all XML strings
    foreach ($LogConfTemplateLine in $LogConfTemplateLines) {
        $NewLogConfXmlLine = $LogConfTemplateLine -replace '{!LogFilePath}', $LogFilePath
        $LogConfXmlLines += $NewLogConfXmlLine
    }

    # ------------------------------------------------------------------------------------------- generate the log-conf.xml
    $LogConfXmlFilename = Join-Path $ConfigFilesPath 'log-conf.xml'
    Write-Debug "Generating log-conf: <$LogConfXmlFilename>"
    Set-Content -Path $LogConfXmlFilename -Value $LogConfXmlLines

    return $LogConfXmlFilename
}
