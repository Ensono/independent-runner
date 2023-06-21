
function Confirm-TrunkBranch() {

    <#
    
    .SYNOPSIS
    Determines if the current branch of the course control is the trunk branch

    .DESCRIPTION
    Sometimes operations need to be performed only when the commands are being run on the 
    trunk branch. This cmdlet returns a boolean to state if this is the case.
    
    This cmdlet currently only supports git
    #>

    [CmdletBinding()]
    param(

        [string[]]
        # List of branches that are considered trunk. This is to accomodate SCS that 
        # may have different names for a trunk
        $names = $env:TRUNK_NAMES,

        [string]
        # Name of the source control provider
        $scs = $env:SCS
    )

    # Set sane defaults
    # Set a default of Git if not set
    if ([String]::IsNullOrEmpty($scs)) {
        $scs = "git"
    }

    $discocmd = ""
    $result = $false

    # determine the command to run and branch names for the supported scs
    switch ($scs) {

        "git" {

            if ($names.length -eq 0) { $names = @("main", "master") }

            $discocmd = "git rev-parse --abbrev-ref HEAD"
        }

        default {

            Write-Warning -Message ("SCS is not currently supported: {0}" -f $scs)
            return $false
        }
    }

    Write-Information ("Checking if trunk branch: {0}" -f $names)

    # Run command to get the branch that is being run
    $branch = Invoke-Expression -Command $discocmd

    if ($names -contains $branch) {
        $result = $true
    }

    return $result
}