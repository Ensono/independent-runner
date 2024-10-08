<#

.SYNOPSIS
Runs external commands with the specified options

.DESCRIPTION
This is a helper function that executes external binaries. All cmdlets and functions that require
executables to be run should use this function. This is so that the Pester tests can mock the function
and Unit tests are possible on all scripts

#>

function Invoke-External {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        # Command and arguments to be run
        $commands,

        [switch]
        # State if should be run in DryRun mode, e.g. do not execute the command
        $dryrun,

        [Int[]]
        # Additional exit codes that are acceptable from the command
        $AdditionalExitCodes = @()
    )

    # Set all of the exit codes that are acceptable
    $exitCodes = @(0) + $AdditionalExitCodes

    foreach ($command in $commands) {

        # Trim the command
        $command = $command.Trim()

        Write-Debug -Message $command

        # Determine if the command should be executed or not
        if (!$dryrun.IsPresent) {
            $execute = $true
        }

        # Add the command to the session so all can be retrieved at a later date, if
        # the session variable exists
        if (Get-Variable -Name Session -Scope global -ErrorAction SilentlyContinue) {
            $global:Session.commands.list += $command

            if ($global:Session.dryrun) {
                $execute = $false
            }
        }

        # If a file has been set in the session, append the command to the file
        if (![String]::IsNullOrEmpty($Session.commands.file)) {
            Add-Content -Path $Session.commands.file -Value $command
        }

        if (!$execute) {
            continue
        }

        # Output the command being called
        Write-Information -MessageData $command

        # Reset the LASTEXITCODE as it can be tripped from a variety of places...
        $global:LASTEXITCODE = 0

        Invoke-Expression -Command $command | Tee-Object -variable output

        # Add the exit code to the session, if it exists
        if (Get-Variable -Name Session -Scope global -ErrorAction SilentlyContinue) {
            $global:Session.commands.exitcodes += $LASTEXITCODE
        }

        # Stop the task if the LASTEXITCODE is greater than 0
        Write-Host ("Permitted exit codes: {0}" -f ($exitCodes -join ", "))
        Write-Host ("Exit code: {0}" -f $LASTEXITCODE)
        if ($LASTEXITCODE -notin $exitCodes) {
            Stop-Task -ExitCode $LASTEXITCODE
        }
    }
}
