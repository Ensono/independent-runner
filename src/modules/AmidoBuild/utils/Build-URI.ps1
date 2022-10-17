
function Build-URI() {

    <#
    
    .SYNOPSIS
    Helper function to build up a valid URI

    #>

    [CmdletBinding()]
    param (
        [string]
        # Server / hostname of the target endpoint
        $server,

        [string]
        # Path of the URI
        $path,

        [string]
        # Port to connect to the remote host on
        $port,

        [hashtable]
        # Hashtable of the query options
        $query,

        [switch]
        # Specify that HTTP should be used instead of HTTPS
        $notls
    )

    # Create the necessary variables
    $scheme = "https://"
    $queryString = ""

    if ($notls.IsPresent) {
        Write-Warning -Message "HTTP encryption should not be turned off"
        $scheme = "http://"
    }

    # iterate around the query hashtable and turn it into an array
    # that can be joined together for the query of the URI
    if ($query.count -gt 0) {
        $queryParts = @()
        foreach ($h in $query.GetEnumerator()) {
            $queryParts += "{0}={1}" -f $h.name, $h.value
        }

        $queryString = "?{0}" -f ($queryParts -join "&")
    }

    # if the the path does not start with a preceeding / add it
    if (!$path.StartsWith("/") -and ![String]::IsNullOrEmpty($path)) {
        $path = "/{0}" -f $path
    }

    # Set a port to be used if one has been specified
    if (![String]::IsNullOrEmpty($port)) {
        $port = ":{0}" -f $port
    }

    $uri = "{0}{1}{2}{3}{4}" -f $scheme, $server, $port, $path, $queryString

    $uri

}