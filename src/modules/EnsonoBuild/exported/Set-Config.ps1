


function Set-Config() {

    <#

    .SYNOPSIS
    Sets up the environment for the module

    .DESCRIPTION
    Cmdlet currently sets the path for the file to hold the commands that are executed
    by the module

    .EXAMPLE
    Set-Config -commandpath ./cmdlog.txt

    Set the path to the command log file `./cmdlog.txt`

    #>

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