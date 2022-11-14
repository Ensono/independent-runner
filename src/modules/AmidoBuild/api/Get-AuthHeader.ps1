
function Get-AuthHeader() {

    <#
    
    .SYNOPSIS
    Generates the correct authentication string to be used in the header
    
    #>

    [CmdletBinding()]
    param (

        [string]
        # Authentication type
        $authType = "basic",

        [securestring]
        # Credentials to be configured
        $credentials,

        [switch]
        # State if to base64 encode the string
        $encode
    )

    $authstr = "Authorization:"

    # switch based on the AuthType and setup the string to pass back
    switch ($authType) {

        "bearer" {
            $authstr += " Bearer"
        }

        default {
            $authstr += " Basic"
        }
    }

    # Create a base64 encoded string of the credentials that have been passed
    $creds = $credentials | ConvertFrom-SecureString -AsPlainText

    if ($encode.IsPresent) {

        $credentialsBytes = [System.Text.Encoding]::Unicode.GetBytes($creds)

        # Encode string content to Base64 string
        $credentialsEncoded =[Convert]::ToBase64String($credentialsBytes)

        # append the credentals onto the end of the authstr
        $authstr += " {0}" -f $credentialsEncoded
    } else {
        $authstr += " {0}" -f $creds
    }

    return $authstr
}