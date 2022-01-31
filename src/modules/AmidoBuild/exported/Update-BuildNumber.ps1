<#

.SYNOPSIS
Update the build number

.DESCRIPTION
Depending on the platform being run, update the build number accordingly

#>

function Update-BuildNumber() {
    [CmdletBinding()]
    param (

        [string]
        # Build number to update to
        $buildNumber = $env:DOCKER_IMAGE_TAG
    )

    # If the buildNumber is null, set it to a default value
    If ([String]::IsNullOrEmpty($buildNumber)) {
        $buildNumber = "workstation-0.0.1"
    }

    # Check that the parameters have been set
    if (Confirm-Parameters -List @("buildNumber")) {

        # If the TF_BUILD environment variable is defined, then running on an Azure Devops build agent
        if (Test-Path env:TF_BUILD) {
            Write-Output ("##vso[build.updatebuildnumber]{0}" -f $buildnumber)
        }
    }
}