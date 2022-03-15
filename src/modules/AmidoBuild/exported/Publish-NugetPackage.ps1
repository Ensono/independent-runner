
function Publish-NugetPackage() {

    <#

    .SYNOPSIS
    Publishes a Nuget Package release using arguments and environment variables

    .DESCRIPTION
    Using the dotnet nuget CLI this script will publish a package to a nuget feed
    #>

    [CmdletBinding()]
    param (

        [string]
        # API Key for NuGet Package Feed
        $APIKey = $env:nuget_api_key,

        [string]
        # Nuget Package Feed URI
        $nugetPackageFeed = "https://api.nuget.org/v3/index.json",

        [string]
        # Packages to Publish
        $packagesToPublish = "**/*.nupkg",

        [string]
        # Whether we should actually push data for this release
        $publishRelease = $env:PUBLISH_RELEASE

    )

    # Check whether we should actually publish
  if ($publishRelease -ne "true" -Or $publishRelease -ne $true) {
    Write-Information -MessageData ("Neither publishRelease parameter nor PUBLISH_RELEASE environment variable set to `'true`', exiting.")
    return
  }

  $dotnet = Find-Command -Name "dotnet"


  # Confirm that the required parameters have been passed to the function
  $result = Confirm-Parameters -List @("APIKey")

  if (!$result) {
    Write-Error "NuGet Package Feed API Key is required"
    return $false
    }

  $arguments = @()
  $arguments += "$packagesToPublish"
  $arguments += "--api-key $APIKeyh"
  $arguments += "--source $nugetPackageFeed"
  $arguments += "--skip-duplicate"

  $commands = @()
  $commands = "{0} nuget push {1}" -f $dotnet, ($arguments -join " ")
  # Run dotnet command
  Invoke-External -Command $commands 
}
