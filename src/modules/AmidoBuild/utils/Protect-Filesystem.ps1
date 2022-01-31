
function Protect-Filesystem() {

    <#
    
    .SYNOPSIS
    Cmdlet to determine that the specified path is within the current directory

    .DESCRIPTION
    A lof of the functions in this module accept a path parameter, which could be relative. It is not
    good practice to allow a relative path to break out of the current location, so this cmdlet checks
    if the specified path is within the current dir.

    If it is then the dirctory will be created if it does not exist, otherwise an error will be generated
    if the path does not exist

    #>

    [CmdletBinding()]
    param (

        [string]
        # Path that is being checked
        $path,

        [Alias("BasePath")]
        [string]
        # Parent path to use to check that the path is a child
        $parentPath
    )

    # Check that the required parameters have been set
    $result = Confirm-Parameters -List @("path")
    if (!$result) {
        return $false
    }

    if ([string]::IsNullOrEmpty($parentPath)) {
        $parentPath = (Get-Location).Path
    }

    # If the path is relative, resolve it to a full path
    # This is done to get rid of any ../ that may exist
    if (![System.IO.Path]::IsPathRooted($path)) {
        Push-Location -Path $parentPath
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        Pop-Location
    }

    # Determiune if the path is a child of the parent path, if it is create it
    # Otherwise throw an error
    if ($path.ToLower().StartsWith($parentPath.ToLower())) {

        if (!(Test-Path -Path $path)) {
            Write-Warning -Message ("Specified output path does not exist, creating: {0}" -f $path)
            
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    } else {
        Write-Error -Message "Specified output path does not exist within the current directory"
        return $false
    }

    return $path
}
