
function Invoke-GitClone() {

    <#
    
    .SYNOPSIS
    Clones a Git repository

    .DESCRIPTION
    This cmdlet will clone a repsoitory from the specified Git provider.

    The repoUrl parameter is used to state where the repository should be retrieved from. This
    can be a short name or a full URL.

    If a short name is provided, e.g. amido/stacks-dotnet, the cmdlet will build up the archive URL
    that will be used download the archive an unpack it.

    Git is not used to get the repository, this is so that there is no dependency on the command
    and means that the URL requested has to be to a zip file for the archive. This is determined
    automatically if using GitHub as the provider.

    .NOTES
    Whilst the cmdlet has been designed so that other providers, such as GitHub, are supported
    for shortnames, it has not been extended beyond GitHub.

    If a repository needs to be retrieved from a different provider please use the full URL
    as the repoUrl parameter.

    .EXAMPLE
    Invoke-GitClone -repo amido/stacks-pipeline-templates -ref refs/tags/v2.0.6 -path support

    As the default provider is GitHub this will result in the archive https://github.com/amido/stacks-pipeline-templates/archive/refs/tags/v.2.06.zip
    being downloaded and unpacked into the `support` directory.

    #>
    
    [CmdletBinding()]
    param (

        [string]
        # Type of VCS to clone from
        $type = "github",

        [string]
        # Path that the repo should be cloned into
        $path = (Get-Location),

        [string]
        [Alias("uri")]
        # Name of the repository to clone
        $repoUrl = $env:AMIDOBUILD_REPOURL,

        [string]
        # Reference to use to download the Zip file for the repository
        $ref,

        [string]
        # The trunk branch to use if ref is empty
        $trunk = "main"
    )

    # if a repo has not been specified then error
    if ([String]::IsNullOrEmpty($repoUrl)) {
        Write-Error -Message "A repository to clone must be specified"
        return
    }

    # If the ref is empty then use $trunk
    if ([String]::IsNullOrEmpty($ref) -or $ref -eq "latest") {
        $ref = $trunk
    }

    # If path is not rooted append it to the current directory
    if (![IO.Path]::IsPathRooted($path)) {
        $path = [IO.Path]::Combine((Get-Location).Path, $path)
    }

    # Create the path if it does not exist
    if (!(Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }

    # If the repo is not a web address build it up
    if (!(Confirm-IsWebAddress -address $repoUrl)) {
        switch ($type) {
            # Build up the URL to download the repo from the ArchiveUrl, if the type is GitHub
            "github" {
                $repoUrl = "https://github.com/{0}/archive/{1}.zip" -f $repoUrl, $ref
            }

            default {
                Write-Error -Message ("Remote source control system is not supported: {0}" -f $type)
                return
            }
        }
    }

    Write-Verbose $repoUrl

    # Determine the path that the zip file should be dowloaded to
    # - create a safeFileName that does not have any strange characters in it
    $url = [System.Uri]$repoUrl
    $safeName = ($url.LocalPath).TrimStart("/") -replace "archive/", ""
    $safeName = $safeName -replace "/", "_"

    $zipPath = [IO.Path]::Combine($path, $safeName)

    Write-Verbose $zipPath

    try {

        # Build up the command to download the zip file
        Invoke-WebRequest -Uri $repoUrl -UseBasicParsing -ErrorAction Stop -OutFile $zipPath

    } catch {

        $_.Exception.Response.StatusCode
        return
    }

    # If the zipPath exists, unpack the zip file
    if (Test-Path -Path $zipPath) {

        # Build up the command to unzip the zip file
        Expand-Archive -Path $zipPath -Destination $path

        # if the ref has been set and is a tag, get the version number
        if ($ref -match "v(.*)") {
            $ref = $matches.1
        }

        # Move the unpacked dir to a dir named after the repo name
        $expandedPath = [IO.Path]::Combine($path, ("{0}-{1}" -f $name, $ref))
        $newPath = [IO.Path]::Combine($path, $name)

        Write-Debug $expandedPath
        Write-Debug $newPath

        Move-Item -Path $expandedPath -Destination $newPath

        Remove-Item -Path $zipPath -Confirm:$false -Force
    }
}