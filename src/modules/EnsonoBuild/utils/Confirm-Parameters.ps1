
function Confirm-Parameters() {

    [CmdletBinding()]
    param (

        [string[]]
        # List of variables that should be checked
        $list
    )

    # Set the result to return
    $result = $false

    # Definde the array to hold missing parameters
    $missing = @()

    # Iterate around the list and check the values
    foreach ($name in $list) {
        $var = Get-Variable -Name $name -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($var.Value)) {
            $missing += $name
        }
    }

    # If there are missing items, throw an error
    # and return false
    if ($missing.count -gt 0) {

        # Write-Error adds a null to the pipleine which means that the $result var ends being an array
        # which looks like @($null, $false)
        # by assigning the result of Write-Error to the £drop var this is avoided
        $drop = Write-Error -Message ("Required parameters are missing: {0}" -f ($missing -join ", "))
    } else {
        $result = $true
    }

    return $result
}