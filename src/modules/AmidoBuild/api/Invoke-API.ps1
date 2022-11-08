
function Invoke-API() {

    <#
    
    .SYNOPSIS
    Internal function to call APIs for endpoints. It uses the Invoke-WebRequest cmdlet

    .DESCRIPTION
    The Amido-Build module has support for publishing content to Wikis via APIs, this cmdlet
    uses the Invoke-WebRequest cmdlet to configure the authentication headers and call
    the API based on the supplied host and path along with the necessary body
    
    #>

    [CmdletBinding()]
    param (

        [string]
        # Method that is to be used
        $method = "GET",

        [string]
        # url to be used to call the endpoint
        $url,

        [Alias("token")]
        [string]
        # Username to be used to connect to the API
        $credentials = [String]::Empty,

        [string]
        # Authentication type, default is basic
        $authType = "basic",

        [string]
        # Content type for the API call
        $contentType = "application/json",

        [string]
        # Body to be passed to the API call
        $body = "",

        [hashtable]
        # Form data to be posted,
        $formData = @{},

        [hashtable]
        # Headers that should be added to the request
        $headers
    )

    # Create a hash of the parameters to pass to Invoke-WebRequest
    $splat = @{
        method = $method
        uri = $url
        contentType = $contentType
        erroraction = "silentlycontinue"
        headers = @{}
    }

    # if headers have been supplied add them to the splat
    if ($headers.count -gt 0) {
        $splat.headers = $headers
    }

    # only set the authentication in the splat if credentials have been supploed
    if (![String]::IsNullOrEmpty($credentials)) {
        $splat.authentication = $authType
        
        # add in the credentials based on the type that has been requested
        switch ($authType) {

            { @("bearer", "oauth") -contains $_} {

                # Create a secuyre string of the credential
                $secPassword = ConvertTo-SecureString -String $credentials -AsPlainText -Force

                $splat.Token = $secPassword
            }

            default {
            
                # Split the credentials out so that the username and password can be
                # used for the PSCredential
                $username, $password = $credentials -split ":", 2
                $secPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
                $psCred = New-Object System.Management.Automation.PSCredential ($userName, $secPassword)

                # Add the credentials
                $splat.Credential = $psCred
            }
        }
    }

    # Add in the body if it not empty and the method is PUT or POST
    # Set as form if the contenttype is multipart/form-data
    if (($formData.count -gt 0 -or ![String]::IsNullOrEmpty($body)) -and @("put", "post") -icontains $method) {
        if ($contentType -contains "multipart/form-data") {
            $splat.form = $formData
        } else {
            $splat.body = $body
        }
    }

    # Make the call to the API
    try {
        Invoke-WebRequest @splat
    } catch {
        $_.Exception
    }

}