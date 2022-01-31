
<#

.SYNOPSIS
Sets up the environment for the module

#>

function Set-Config() {

    [CmdletBinding()]
    param (

        [string]
        # Set the file to be used for command log
        $commandpath
    )

    if (![String]::IsNullOrEmpty($commandpath)) {

        # ensure the parent path for the commandpath exists
        if (!(Test-Path -Path (Split-Path -Path $commandpath -Parent))) {
            Write-Error -Message "Specified path for command log does not exist"
        } else {

            if (!([string]::IsNullOrEmpty((Get-Variable -Name Session -Scope Global -ErrorAction SilentlyContinue)))) {
                $Session.commands.file = $commandpath
            }
        }
    }
}