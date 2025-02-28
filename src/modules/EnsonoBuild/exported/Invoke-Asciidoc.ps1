
function Invoke-Asciidoc() {

    [CmdletBinding()]
    param (

        [string]
        [ValidateSet("pdf", "html", "docbook")]
        # Format of the document to generate
        $Format,

        [string]
        # Output filename
        $Output,

        [string]
        # The path to the file to convert
        $Path,

        [string[]]
        [Alias("Libs")]
        # List of libraries that need to be loaded to generate the document
        $Libraries = @(),

        [string[]]
        # List of attributes to be be added to the command
        $Attributes = @()
    )

    # Configure variables
    $arguments = @()
    $command = ""
    switch ($Format) {
        "pdf" {
            $command = Find-Command -Name "asciidoctor-pdf"
        }
        "html" {
            $command = Find-Command -Name "asciidoctor"
            $arguments += @("-b html5")
        }
        "docbook" {
            $command = Find-Command -Name "asciidoctor"
            $arguments += @("-b docbook5")
        }
    }

    Write-Information ("Generating {0} document: {1}" -f $Format, $Output)

    # Get all the tokens that are available
    $tokens = Set-Tokens

    # Ensure the tokens are replaced the settings
    $Output = Replace-Tokens -Tokens $tokens -Data $Output
    $Path = Replace-Tokens -Tokens $tokens -Data $Path

    # Add in the extra arguments
    $arguments += @("-o `"{0}`"" -f (Split-Path -Path $Output -Leaf))

    # If there are any libraries, iterate around each of them and add to the arguments
    if ($Libraries.count -gt 0) {
        foreach ($lib in $Libraries) {
            $arguments += @("-r {0}" -f $lib)
        }
    }

    # if there are any attributes add them to the arguments
    if ($Attributes.count -gt 0) {
        foreach ($attr in $Attributes) {
            $arguments += @("-a {0}" -f $attr)
        }
    }

    # Add in the output directory
    $arguments += @("-D `"{0}`"" -f (Split-Path -Path $Output -Parent))

    # Build up the command to be run
    $cmd = "{0} {1} {2}" -f $command, ($arguments -join " "), $path

    # Now invoke the command
    Invoke-External $cmd
}