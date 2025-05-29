
function Invoke-Pandoc {

    [CmdletBinding()]
    param (

        [string]
        # The format that the input document is in
        $From = "docbook",

        [string]
        # The form of the resultant file
        $To,

        [string]
        # Output path
        $Output,

        [string]
        # Path to the file to read in
        $Path,

        [string[]]
        # String array of command line attributes to add to the command line
        $Attributes = @()
    )

    # Get all the tokens that are available
    $tokens = Set-Tokens

    # Ensure the tokens are replaced the settings
    $Output = Replace-Tokens -Tokens $tokens -Data $Output
    $Path = Replace-Tokens -Tokens $tokens -Data $Path

    # Find the pandoc command
    $command = Find-Command -Name "pandoc"

    # Add in the arguments for the command
    $arguments = @()
    $arguments += "-f {0}" -f $From
    $arguments += "-t {0}" -f $To
    $arguments += "-o `"{0}`"" -f $Output

    # Add in any attrbutes that have been set, and ensure that any that have tokens are replaced
    foreach ($Attribute in $Attributes) {
        $arguments += (Replace-Tokens -Tokens $tokens -Data $Attribute)
    }

    # Build the command
    $cmd = "{0} {1} `"{2}`"" -f $command, ($arguments -join " "), $Path

    Invoke-External $cmd
}
