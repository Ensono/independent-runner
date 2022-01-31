<#

.SYNOPSIS
Get dependencies for the build

.DESCRIPTION
Retrieve the dependencies for the build.

Can retrieve a list of GitHub repositories into the lcoal directory

#>

function Get-Dependencies {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [string]
        # Type of dependencies that are to be downloaded
        $type,

        [string[]]
        # List of deps to download
        $list
    )

    # Get the dependencies for the specified type
    switch ($type) {
        "github" {

            # iterate around the list of deps
            foreach ($repo in $list) {

                # get the name and the ref from the specified repo
                $name, $ref = $repo -split "@"

                Invoke-GitClone -Repo $name -Ref $ref -path support
            }
        }

        default {

            Write-Error -Message $("VCS type is not recognised: {0}" -f $type)
        }
    }
}