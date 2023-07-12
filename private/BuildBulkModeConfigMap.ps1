Set-StrictMode -Version 3

function BuildBulkModeConfigMap {
    param (
        [string]$BulkMode
    )

    $ConfigOverrideMap = switch ($BulkMode) {
        'Parallel' { @{ 'sfdc.useBulkApi' = 'true'; 'sfdc.bulkApiSerialMode' = 'false' } }
        'Serial' { @{ 'sfdc.useBulkApi' = 'true'; 'sfdc.bulkApiSerialMode' = 'true' } }
        Default { @{ 'sfdc.useBulkApi' = 'false' } }
    }

    return $ConfigOverrideMap
}
