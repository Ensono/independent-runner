
function Find-Projects() {

    [CmdletBinding()]
    param (

        [string]
        # Pattern to use to find the necessary files
        $pattern,

        [Alias("dir")]
        [string]
        # Path in which to search
        $path,

        [Switch]
        # State if looking for only directories
        $directory
    )

    # Create a hash table to be used to splat in the arguments for Get-ChildItem
    $splat = @{
        Path = $path
        Filter = $pattern
        Directory = $directory.IsPresent
        Recurse = $true
    }

    Get-ChildItem @splat
}