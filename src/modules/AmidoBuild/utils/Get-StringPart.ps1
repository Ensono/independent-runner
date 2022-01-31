
<#

.SYNOPSIS
    Get-StringPart returns part of a string based on the index and delimiter

.DESCRIPTION
    Get-StringPart is used to get part of a string based on the specified delimiter and index

.EXAMPLE
    Get-StringPart -Phrase "git clone https://github.com/amido/stacks-pipeline-templates" -Delimiter " " -Index 0
    "git"

#>
function Get-StringPart() {

    [CmdletBinding()]
    param (
        [string]
        # Phrase to extract from
        $phrase,

        [string]
        # Delimieter used to split up string
        $delimiter = " ",

        [int]
        # Item number stating which part of the string is required
        $item
    )

    # if the item is less than 1, then throw an error
    if ($item -lt 1) {
        Write-Error -Message "Item must be equal to or great than 1"
        return
    }

    # Split the phrases into parts
    $parts = $phrase -split $delimiter

    # if the index is greater than the number of parts, raise an error
    if ($item -gt $parts.count) {
        Write-Error -Message ("Specified item '{0}' is greater than the number of parts: {1}" -f $item, $parts.count)
    } else {
        return $parts[$item - 1]
    }
}

