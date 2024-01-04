function Find-Command {

    <#

    .SYNOPSIS
    Determine the full path to the specified command

    .DESCRIPTION
    This function accepts the name of a command to look for in the path. It then uses Get-Command to return
    the full path of that command, if it has been found.

    If the command cannot be found an error is raised and the function exits with error code 1.

    .EXAMPLE

    Find-Command -Name terraform

    #>

    [CmdletBinding()]
    param (

        [string]
        # Name of the command to find
        $Name
    )

    # Find the path to the named command
    $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($command)) {
        Write-Error -Message ("'{0}' command cannot be found in the path, please ensure it is installed" -f $Name)
        return
    } else {
        Write-Information ("Tool found: {0}" -f $command.Source)
    }

    return $command
}