
function Get-ConfluencePage() {

    <#
    
    .SYNOPSIS
    Get the ID for the specified confluence page

    .DESCRIPTION
    Get information about the specified page, this includes the pageId, version and checksum

    The function will return an object that containing the necessary information. This is safer
    than returning multiple values as sometimes the other values are not required and can
    cause issues if not caught

    #>

    [CmdletBinding()]
    param (
        [string]
        # URL of confluence to call
        $url,

        [string]
        # Credentials to be used to access confluence
        $credentials
    )

    # Create the object that will be returned to the calling function
    $details = [PSCustomObject]@{
        ID = ""
        Version = ""
        Checksum = ""
        Create = $false
    }

    $res = Invoke-API -url $url -credentials $credentials

    if ($res -is [System.Exception]) {
        # check to see if the response is that the page could not
        # be found, in which case the page needs to be created
        if ($res.Response.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
            Write-Information -MessageData "Page cannot be found, creating new page"
            $details.Version = 1
            $details.Create = $true
        } else {
            Stop-Task -Message $res.Message
        }
    } else {

        # The page has been found so get the page ID
        $content = ConvertFrom-JSON -InputObject $res.Content
        $details.ID = $content.results[0].id
        $details.Version = $content.results[0].version.number

        # As the page exists, get the checksum of the page
        $uri = [System.Uri]$url
        $propUrl = "{0}://{1}:{2}{3}/{4}/property" -f $uri.Scheme, $uri.DnsSafeHost, $uri.Port, $uri.AbsolutePath, $details.ID

        $res = Invoke-API -url $propUrl -credentials $credentials
        $properties = (ConvertFrom-Json -InputObject $res.Content).results

        foreach ($prop in $properties) {
            if ($prop.key -eq "checksum") {
                $details.Checksum = $prop.value[0]
            }
        }
    }

    return $details
}