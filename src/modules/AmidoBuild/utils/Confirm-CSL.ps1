<#

.SYNOPSIS
Tests input string is a valid comma delimited list
#>
function Confirm-CSL() {

[CmdletBinding()]
param (

    [string]
    # Input string to test
    $data = ""
)

# Import helper functions
# N/A

$data -match "^[0-9a-zA-Z=-.]+(,[0-9a-zA-Z=-.]+)*$"
}