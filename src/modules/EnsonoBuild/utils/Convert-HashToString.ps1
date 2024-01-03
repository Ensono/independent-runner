
function Convert-HashToString() {

    [CmdletBinding()]
    param (

        [Parameter(
            ValueFromPipeline = $true
        )]
        [Hashtable]
        # Hashtable to write out as a string
        $hash
    )

    # Check that all the required parameters have been set
    $result = Confirm-Parameters -List @("hash")
    if (!$result) {
        return
    }

    # Start the string for the hashtable
    $hashStr = "@{"

    # create an array for the string parts so that all the nessary
    # strings can be joined together with the correct delimiter
    $stringParts = @()

    $keys = $hash.Keys

    foreach ($key in $keys) {

        # set the quotes to use
        $quotes = '"'

        # get the the value of the key
        $value = $hash[$key]

        # Check to see if the value is a hashtable, if it is then it needs
        # be converted to a string
        if ($value -is [System.Collections.Hashtable]) {
            $value = Convert-HashToString -hash $value
            $quotes = $null
        }

        if ($value -is [System.Array]) {
            $value = Convert-ArrayToString -arr $value
            $quotes = $null
        }

        if ($key -match "\s") {
            $key = '"{0}"' -f $key
        }
        
        $stringParts += '{0} = {2}{1}{2}' -f $key, $value, $quotes
    
    }

    $hashStr += $stringParts -join "; "
    $hashStr += "}"

    return $hashStr
}
