Set-StrictMode -Version 3

function InvokeSfDataloaderJavaClass{
	[CmdletBinding()]
	param (
		[Parameter()][string[]]$SystemPropertiesList,
		[Parameter(Mandatory)][string]$ClassName,
		[Parameter()][string[]]$ArgumentList
	)

    $JavaHome = $env:JAVA_HOME
    $ClassPath = "$PSScriptRoot\..\dataloader\*.jar"

    # --- find a jar. NOTE: We expect exactly one .jar file here!
    $ClassPathFiles = @(Get-ChildItem -Path $ClassPath)
    if (!($ClassPathFiles)) {
        throw "NOT FOUND <$ClassPath> - Check Installation instructions!"
    } elseif ($($ClassPathFiles.Count) -ne 1) {
        throw "MORE THAN ONE FILE FOUND <$ClassPath> - Check Installation instructions!"
    } else {
        $ClassPath = $ClassPathFiles[0].FullName
    }

	Write-Verbose "JavaHome: $JavaHome"
	Write-Debug   "PSScriptRoot: $PSScriptRoot"
	Write-Verbose "ClassPath: $ClassPath"
	Write-Debug   "ClassName: $ClassName"
    Write-Debug   "ArgumentList: $ArgumentList"
    if ($debug) { 
		Write-Debug '--- BEGIN EchoArgs'
		& "$PSScriptRoot\..\private\EchoArgs.exe" '-cp' $ClassPath $SystemPropertiesList $ClassName $ArgumentList | Write-Debug
		Write-Debug '--- END EchoArgs'
		pause 
	}
    $Result = & "$JavaHome\bin\java" '-cp' $ClassPath $SystemPropertiesList $ClassName $ArgumentList
    [string]$s = $Result
    return $s
}

