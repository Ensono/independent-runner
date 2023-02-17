<#
    .NOTES
        There is no PowerShell function to make a deep copy.
        Clone() function for hashtables does only a shallow copy.
        Reference has to be used here to handle null or empty objects.
 
    .DESCRIPTION
        This function writes a deep copy of an input object
        to a reference passed.
        If original object is null, then null will be returned.
        Otherwise object is copied via memory stream.
 
    .PARAMETER Original
        It is an object that will be copied.
        It can be null.
 
    .PARAMETER DeepClone
        It is a reference to an existing object.
        This object will become a deep copy of original object passed to this function.
        [ref] is used as PowerShell returns all non-captures stream output,
        not just argument of the return statement.
        e.g. it will not return empty array, but null instead.
 
    .EXAMPLE
        $clone = $null
        Copy-Object -Original $original -DeepClone ([ref]$clone)
#>
function Copy-Object {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $Original,

        [Parameter(Mandatory=$true)]
        [ref] $DeepClone
    )

    if($null -eq $Original)
    {
        $DeepClone.Value = $null
    }
    else
    {
        $memStream = new-object IO.MemoryStream
        $formatter = new-object Runtime.Serialization.Formatters.Binary.BinaryFormatter
        $formatter.Serialize($memStream, $Original)
        $memStream.Position = 0
        $DeepClone.Value = $formatter.Deserialize($memStream)
        $memStream.Close()
    }
}