foreach ($directory in @('Private', 'Public')) {
    Get-ChildItem -Path "$PSScriptRoot\$directory\*.ps1" | ForEach-Object {. $_.FullName}
}

New-Alias sfextract Export-SfRecords -Force
New-Alias sfinsert Add-SfRecords -Force
New-Alias sfupdate Update-SfRecords -Force
New-Alias sfupsert Import-SfRecords -Force
New-Alias sfauth Get-SfAuthToken -Force
