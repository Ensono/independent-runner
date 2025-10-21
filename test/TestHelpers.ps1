# Test helper functions shared across all Pester tests
# This file is dot-sourced by test files, not imported as a module

<#
.SYNOPSIS
Creates a unique temporary directory for test isolation.

.DESCRIPTION
Generates a temporary directory with a unique GUID-based name to prevent
conflicts between test runs. The directory is created in the system temp path.

.OUTPUTS
String - The full path to the created temporary directory.

.EXAMPLE
$testDir = New-TestDir
# Creates something like: C:\Users\user\AppData\Local\Temp\PesterTest_a1b2c3d4
#>
function New-TestDir {
    $tempPath = [System.IO.Path]::GetTempPath()
    $uniqueFolderName = "PesterTest_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    $testFolderPath = [System.IO.Path]::Combine($tempPath, $uniqueFolderName)
    New-Item $testFolderPath -ItemType Directory -Force | Out-Null
    return $testFolderPath
}
