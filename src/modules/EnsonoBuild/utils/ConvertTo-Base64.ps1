
function ConvertTo-Base64() {

    [CmdletBinding()]
    param (
        [string]
        # Value that needs to be converted to base 64
        $value
    )

    # Get the byte array for the string
    $bytes = [System.Text.Encoding]::ASCII.GetBytes(($value))

    # Encode the string
    $encoded = [Convert]::ToBase64String($bytes)

    # return the encoded string
    return $encoded
}