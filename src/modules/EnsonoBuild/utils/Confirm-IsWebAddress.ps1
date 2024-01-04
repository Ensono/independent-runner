
function Confirm-IsWebAddress() {

    [CmdletBinding()]
    param (

        [string]
        # Address to confirm
        $address
    )

    $uri = $address -as [System.URI]

    $uri.AbsoluteURI -ne $null -and $uri.Scheme -match 'https?'
}