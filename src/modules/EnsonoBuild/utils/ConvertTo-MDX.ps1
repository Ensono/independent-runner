

function ConvertTo-MDX {

    <#

    .SYNOPSIS
    Convert the specified Markdown file to MDX supported format

    .DESCRIPTION
    The Stacks documentation website uses Docusarus which means that any HTML in a markdown file
    needs to be in JSX format. This is not natively supported by MD or Asciidoc so thius script will
    take the specified MD file, convert the contents and write out to the specified path

    #>

    [CmdletBinding()]
    param (

        [string]
        # Path the input MD file
        $path,

        [string]
        # Path specifying where the file should be saved to
        $destination
    )

    # Check that the necessary parameters have been supplied
    $result = Confirm-Parameters -list ("path", "destination")
    if (!$result) {
        return $false
    }

    # Check that the path exists
    if (!(Test-Path -Path $path)) {
        Write-Error -Message ("Specified MD file does not exist: {0}" -f $path)
        return $false
    }

    # Ensure that the directory for the destination exists
    $parent = Split-Path -Path $destination -Parent
    if (!(Test-Path -Path $parent)) {
        Write-Information -MessageData ("Creating output directory: {0}" -f $parent)
        New-Item -ItemType Directory -Path $parent | Out-Null
    }

    # Read in the contents of the markdown file
    $data = Get-Content -Path $path -Raw

    # JSX conversion
    # -- class to className
    $data = $data -replace "class=`"", "className=`""

    # -- set styles
    $styles = $data | Select-String -Pattern "style=`"(.*)`"" -AllMatches

    # Iterate around all of the styles and set the necessary replacement
    # This is done because the style attributes need to be separated by comma and the values surrounded by quotes
    foreach ($style in $styles.Matches) {

        $modified = $style.groups[1].value -split "," | ForEach-Object { 
            $_ -replace "(.*):\s+(.*)", '$1: "$2"'
        }

        $modified = $modified -replace '"', "'"
        
        # Perform the replacement in the main data using the value of the style as the key
        # for the replacement
        $data = $data -replace ("`"{0}`"" -f $style.groups[1].value), ("{{{{ {0} }}}}" -f ($modified -join ","))
    }

    Set-Content -Path $destination -Value $data

    Write-Information -MessageData ("Created MDX file: {0}" -f $destination)
}
