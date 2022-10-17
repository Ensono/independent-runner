
function Get-PageImages() {

    <#
    
    .SYNOPSIS
    Retrieves all the src locations of images in the HTML

    .DESCRIPTION
    Reads the src for all img tags in the specified HTML and returns a unique list of the 
    local files.

    Any full web addresses are ignored.

    The value returned is an array of hashtables with the following format:

        @{
            local = ""
            remote = ""
        }

    Thsi is so that the calling function can fiund the page to the image to upload and then set 
    the remote location for any replacements that need to be performed

    #>

    [CmdletBinding()]
    param (
        [string]
        # Data to be analysed
        $data,

        [string]
        # Pattern to be used to find the images
        $pattern = "<img src=`"(.*?)`""
    )

    # Create local arrays to be used
    $register = @()
    $images = @()

    # parse the content
    $res = [Regex]::Matches($data, $pattern)

    # loop around the matchaes and add to the array
    # do not add items that are a full url
    foreach ($img in $res) {

        $src = $img.groups[1].value

        if (!$src.StartsWith("http") -and ($register -notcontains $src) -and !$src.StartsWith("data:image")) {
            $images += @{
                local = $src
                remote = ""
            }
            $register += $src
        }
    }

    # Return the images array
    # The comma is required to force PowerShell to return an array when there is only
    # one entry, otherwise just a single hashtable is returned
    , $images

}