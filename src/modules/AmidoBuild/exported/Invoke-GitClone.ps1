
function Invoke-GitClone() {

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