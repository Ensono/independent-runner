<#
    .NOTES
        This function provides two merge modes:
        - normal (no data loss, arrays merge, but removes duplicates)
        - shallow (only array from primary hashtable is taken)
 
    .DESCRIPTION
        This function merges deeply two hashtables without data loss.
        In case of object mismatch, first hashtable will have priority.
        Value-objects like strings or integers will be taken from primary hashtable.
        Arrays will be merged without duplicates in normal mode.
        In shallow mode array from primary hashtable will be taken.
 
    .PARAMETER primary
        First hashtable to merge.
        This will have priority.
        It can be null or empty.
 
    .PARAMETER secondary
        Second hashtable to merge.
        It can be null or empty.
 
    .PARAMETER shallow
        When switched ON only shallow merge is performed.
        Arrays will not be merged, but array from primary hashtable will be taken.
 
    .EXAMPLE
        Merge-Hashtables -primary $primary -secondary $secondary
        Merge-Hashtables -primary $primary -secondary $secondary -shallow
#>
function Merge-Hashtables {

    [CmdletBinding()]
    [OutputType([hashtable])]
    Param
    (
        [Parameter(Mandatory=$false)]
        [hashtable] $primary,

        [Parameter(Mandatory=$false)]
        [hashtable] $secondary,

        [Parameter(Mandatory=$false)]
        [switch] $shallow
    )

    if($primary.Count -eq 0) {
        return $secondary
    }
    if($secondary.Count -eq 0) {
        return $primary
    }

    # hshtables and dictionaries can be merged
    $mergableTypes = @(
        "Hashtable"
        "Dictionary``2"
    )

    # variable needs to exist to apply [ref]
    $primaryCopy, $secondaryCopy = $null
    $primaryCopy = Copy-Object -Original $primary
    $secondaryCopy = Copy-Object -Original $secondary

    $duplicateKeys = $primaryCopy.keys | Where-Object {$secondaryCopy.ContainsKey($_)}
    foreach ($key in $duplicateKeys)
    {
        if($null -ne $primaryCopy.$key -and $null -ne $secondaryCopy.$key)
        {
            # mergable types merge recursively
            if ($mergableTypes -contains $primaryCopy.$key.GetType().Name -and
                $mergableTypes -contains $secondaryCopy.$key.GetType().Name)
            {
                $primaryCopy.$key = Merge-Hashtables -primary $primaryCopy.$key -secondary $secondaryCopy.$key -shallow:$shallow
            }

            # merge arrays (unless it is in shallow mode)
            if (-not $shallow -and
                $primaryCopy.$key.GetType().Name -eq "Object[]" -and
                $secondaryCopy.$key.GetType().Name -eq "Object[]")
            {
                $result = @()

                # because Object[] can contain many different types, Unique of Select may not work properly
                # hence iterate over each of the two arrays
                foreach ($item in ($primaryCopy.$key + $secondaryCopy.$key))
                {
                    # Switch on the type of the item to determine how to add the information
                    switch ($item.GetType().Name)
                    {
                        # unique strings and integers
                        {$_ -in "String","Int32"} {
                            if ($result -notcontains $item) {
                                $result += $item
                            }
                        }

                        default {
                            $result += $item
                        }
                    }
                }

                # assign the result back to the primary array
                $primaryCopy.$key = $result
            }
        }

        # force primary key, so remove secondary conflict
        $secondaryCopy.Remove($key)
    }

    # join the two hash tables and return to the calling function
    $primaryCopy + $secondaryCopy
}