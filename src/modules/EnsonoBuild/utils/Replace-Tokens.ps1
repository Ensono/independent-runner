
function Replace-Tokens() {

    <#
    
    .SYNOPSIS
    Replaces the tokens in the specified data with the values in the hashtable

    #>

    [CmdletBinding()]
    param (

        [hashtable]
        # Hashtable of the tokens and the values to be replaced
        $tokens = @{},

        [string[]]
        # String that should have tokens replace
        $data,

        [string[]]
        # Delimeters to be used
        $delimiters = @("{{", "}}")
    )

    # get the start and stop delimiters
    $start = [Regex]::Escape($delimiters[0])
    $stop = [Regex]::Escape($delimiters[1])

    # Build up the pattern to find the automatic tokens
    # Currently the only one supported is "date" using the Uformat
    $pattern = '{0}\s*(date:.*?)\s*{1}' -f $start, $stop

    # Get any date based tokens from the data and ensure it is converted and added to the tokens
    $found = $data | Select-String -Pattern $pattern -AllMatches
    if ($found) {
        foreach($m in $found.Matches) {
            $date_pattern = $m.groups[1].value
            $tokens[$date_pattern] = Get-Date -Uformat ($date_pattern -split ":")[1].Trim()
        }
    }


    # Iterate around the tokens that have been passed
    foreach ($item in $tokens.GetEnumerator()) {

        # Build up the regular expression that will be used to performt he replacement
        $pattern = '{0}\s*{1}\s*{2}' -f $start, $item.Key, $stop

        $data = $data -replace $pattern, $item.Value
    }

    # ensure that an empty array is returned if the data is empty
    if ($data.count -eq 1 -and [String]::IsNullOrEmpty($data[0])) {
        $data = @()
    }

    # Return the data to the calling function
    $data

}