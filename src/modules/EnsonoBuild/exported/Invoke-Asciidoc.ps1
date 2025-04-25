
function Invoke-Asciidoc() {

    <#

    .SYNOPSIS
    Runs AsciiDoc to convert documents to the desired format

    .DESCRIPTION
    This cmdlet provides direct access to the AsciiDoc commands. It allows more configuration
    than the Build-Documentation cmdlet.

    Like the Build-Documentation cmdlet the output format can be specified, either PDF or HTML. Markdown
    is not yet supported.

    To make it more flexible the cmdlet takes a JSON configuration file which governs how the command
    will run. For example:

    ```
    {
        "title": "MRBuild Manual",
        "output": "{{ basepath }}/outputs/docs/{{ format }}",
        "trunkBranch": "main",
        "path": "{{ basepath }}/docs/index.adoc",
        "libs": [
            "asciidoctor-diagram"
        ],
        "pdf": {
            "attributes": [
                "pdf-theme={{ basepath }}/docs/conf/pdf/theme.yml",
                "pdf-fontsdir=\"{{ basepath }}/docs/conf/fonts;GEM_FONTS_DIR\"",
                "allow-uri-read"
            ]
        }
    }
    ```

    As can be seen the cmdlet supports inserting values into the strings. This allows for the most
    flexibilty. For example the `basepath` is determined automatcially or by specification and this
    is inserted into the output path using the {{ basepath }} token.

    The format is still specified on the command line. The configuration for the format is specified
    as another node in the configuration, in this case the attributes for PDF can be seen.

    In addition to the two tokens that are added by the cmdlet, "basepath" and "format", all environment
    variables are tokens that can be subsituted in the settings file or on the commannd line. For example
    if an environment variable of "BUILDNUMBER" exists and has a value of "1.2.3" the following "attr_a={{ BUILDNUMBER }}"
    would result in a substitution of "attr_a=1.2.3"

    The templating is resolved across the whole configuration file before it is used.

    .NOTES

    This cmdlet will eventually supercede the Build-Documentation cmdlet

    .EXAMPLE

    Invoke-AsciiDoc -pdf -folder . -config ./config.json -output outputs/

    Generate a PDF document from the current folder and put the resultant file in
    the `outputs/` directory.
    #>

    [CmdletBinding()]
    param (

        [string]
        $Format, 

        #[string]
        # Path to configuration file with all the necessary settings
        # If specified additional specific parameters are specifed, those values will
        # override the ones in the configuration file
        #$config,

        [string[]]
        $Libraries,

        [string]
        # Output filename
        $Output,

        [string]
        # The path to the file to convert
        $Path,

        [string[]]
        # List of attributes to pass to the AsciiDoc command
        $attributes,

        [string]
        [ValidateSet('info', 'warn', 'warning', 'error', 'fatal')]
        # A level of logging which will trigger a failed exit code
        $failureLevel = "warn",

        [Int[]]
        # List of exit codes that are accepatable
        # Zero is always accepted
        $ExitCodes = @()
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
    # $arguments += @("-o `"{0}`"" -f (Split-Path -Path $Output -Leaf))
    $arguments += "-o `"{0}`"" -f $Output

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

    # Stitch the full command together
    $cmd = "{0} {1} {2}" -f ($command -join " "), ($arguments -join " "), (Replace-Tokens -Tokens $tokens $settings.path), "--failure-level ${failureLevel}"

    # Execute the command
    Invoke-External -Command $cmd -AdditionalExitCodes $ExitCodes

    # Output the exitcode of the command
    $LASTEXITCODE
}
