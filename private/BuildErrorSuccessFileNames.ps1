Set-StrictMode -Version 3

function BuildErrorSuccessFileNames {
    param (
        [string]$Path
    )

    # --------------------------------------- Build error/success file names
    $CsvFilePath = Split-Path -Path $Path
    $CsvFileName = Split-Path -Path $Path -Leaf
    $PathSuccessFile = Join-Path $CsvFilePath $CsvFileName.Replace('.csv', '-SUCCESS.csv')
    $PathErrorFile = Join-Path $CsvFilePath $CsvFileName.Replace('.csv', '-ERROR.csv')

    # --------------------------------------- Build Config Override Map
    $ConfigOverrideMap = @{
        'process.outputSuccess' = $PathSuccessFile
        'process.outputError'   = $PathErrorFile
    }

    return $ConfigOverrideMap
}
