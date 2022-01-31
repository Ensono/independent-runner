
function Convert-ArrayToString() {

    [CmdletBinding()]
    param (

        [Parameter(
            ValueFromPipeline = $true
        )]
        [System.Array]
        # array to write out as a string
        $arr
    )

    # Check that all the required parameters have been set
    $result = Confirm-Parameters -List @("arr")
    if (!$result -and !($arr -is [System.Object[]])) {
        return
    }

    # Start the string for the array
    $arrStr = "@("

    # create an array for each of the string parts,
    # this is so that the array can be joined together with the correct delimiter
    $stringParts = @()

    foreach ($value in $arr) {

        # set the quotes to use
        $quotes = '"'

        if ($value -is [System.Object[]]) {
            $value = Convert-ArrayToString -arr $value
            $quotes = $null
        }

        if ($value -is [System.Collections.Hashtable]) {
            $value = Convert-HashToString -hash $value
            $quotes = $null
        }

        $stringParts += '{0}{1}{0}' -f $quotes, $value
    }

    $arrStr += $stringParts -join ", "
    $arrStr += ")"

    return $arrStr
}
