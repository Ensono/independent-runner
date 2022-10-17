
function Get-Checksum() {

    <#
    
    .SYNOPSIS
    Helper function to get the MD5 checksum for the contents of a file or a string

    #>

    [CmdletBinding()]
    param (
        [Alias("file")]
        [string]
        # Path to file or the content to get the hash for
        $content
    )

    # Attempt to find the file
    if (Test-Path -Path $content) {
        $content = Get-Content -Path $content -Raw
    }

    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($content)))

    # remove the hypens from the string
    $hash = $hash -replace "-", ""

    return $hash
}