

function Format-HelpSyntax() {

    <#
    
    .SYNOPSIS
    Take the SYntax object producted from Get-Help and return as an array that can be used in the documentation
    
    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        # Syntax object to format
        $Syntax,

        [string]
        # The character to use to join the array
        $JoinChar = "\n\n"
    )
    
    # Setup the arryay to hold all the syntax lines
    $syntaxLines = @()

    # Iterate around the syntax items
    $Syntax.syntaxItem | ForEach-Object {

        # Reset the syntax string
        $syntaxLine = "{0} " -f $help.Name

        # iterate around the parameters of the item
        $_.parameter | ForEach-Object {

            if ($_.required) {
                $syntaxLine += "-{0} " -f $_.name
            }
            else {
                $syntaxLine += "[-{0}] " -f $_.name
            }

            # Add the parameterValue to the syntax if it not empty
            if (![string]::IsNullOrEmpty($_.parameterValue)) {
                $syntaxLine += "<{0}> " -f $_.parameterValue
            } 
        }

        $syntaxLines += $syntaxLine.TrimEnd()
    }


    # Return the syntax lines as a string, joined by new lines
    return ($syntaxLines -join $JoinChar).TrimEnd()
}
