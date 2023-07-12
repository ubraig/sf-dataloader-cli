Set-StrictMode -Version 3

function InitializeConfigTempDir {
#    $ConfigTempDir = (Get-Location).Path
#    $ConfigTempDir =  Join-Path $Env:temp 'SfDataloader'
    $ConfigTempDir =  Join-Path (Get-Location).Path '.SfDataloaderCli'

    if (!(Test-Path $ConfigTempDir)) {
        $dummy = New-Item -ItemType "directory" -Path $ConfigTempDir
        Write-Debug "Dummy: <$dummy>"
    }
    Write-Verbose "ConfigTempDir: <$ConfigTempDir>"
    return $ConfigTempDir
}
