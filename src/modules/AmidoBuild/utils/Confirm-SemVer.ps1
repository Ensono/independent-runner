<#

.SYNOPSIS
Tests version input is valid SemVer

#>
function Confirm-SemVer() {

[CmdletBinding()]
param (

    [string]
    # Value to test as Semantic Version
    $version
)

# Import helper functions
# N/A

$version -match "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$"
}