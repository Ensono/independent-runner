<#
    .NOTES
        There is no PowerShell function to make a deep copy.
        Clone() function for hashtables does only a shallow copy.
        Reference has to be used here to handle null or empty objects.

        As of PowerShell 7 BinaryFormatter is no longer available and it is
        not possible to use and serialise. This has now been converted to use the XML
        serialiser
 
    .DESCRIPTION
        This function writes a deep copy of an input object
        to a reference passed.
        If original object is null, then null will be returned.
        Otherwise object is copied via memory stream.
 
    .PARAMETER Original
        It is an object that will be copied.
        It can be null.
 
    .EXAMPLE
        $clone = Copy-Object -Original $original
#>
function Copy-Object {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Original
    )

    if($null -eq $Original)
    {
        return $null
    }
    else
    {
        $s = [System.Management.Automation.PSSerializer]::Serialize($Original, [int32]::MaxValue)
        return [System.Management.Automation.PSSerializer]::Deserialize($s)
    }
}