
[CmdletBinding()]
param (
)

$pesterErrorCodePath = "./test"
$pesterErrorCodeFile = ".PesterErrorCode"
$pesterErrorCodeFilePath = "${pesterErrorCodePath}/${pesterErrorCodeFile}"

if (Test-Path -Path $pesterErrorCodeFilePath -PathType leaf) {
    Write-Error "ERROR: Test Failures, exiting non-zero to fail the build..."
    $exitCode = Get-Content -Path $pesterErrorCodeFilePath
    exit $exitCode
}
