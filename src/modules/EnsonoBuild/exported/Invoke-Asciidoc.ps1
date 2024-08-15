
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

        [Parameter(
            ParameterSetName="pdf"
        )]
        [switch]
        # State that the document should be PDF
        $pdf,

        [Parameter(
            ParameterSetName="html"
        )]
        [switch]
        # State that the document should be HTML
        $html,

        [string]
        # Path to configuration file with all the necessary settings
        # If specified additional specific parameters are specifed, those values will
        # override the ones in the configuration file
        $config,

        [string]
        # Base path from which all paths will be derived
        # By default this will be the current directory, but in docker this should be the dir
        # that the directory is mapped into
        $basepath = $(Get-Location),

        [alias("folder", "template")]
        [string]
        # Path to the AsciiDoc template to render
        $path,

        [string]
        # Full path for the built document
        $output,

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

    # Define variables to be used in the function
    $cmdline = @()
    $extension = ""

    # Create an empty config hashtable to be used to grab the settings for the generation
    $settings = @{
        title = ""
        output = ""
        path = ""
        trunkBranch = ""
        libs = @()
        pdf = @{
            attributes = @()
        }
        html = @{
            attributes = @()
        }
    }

    # Define the tokens hashtable for any replacements
    $tokens = @{
        "format" = $PSCmdlet.ParameterSetName
        "basepath" = $basepath
    }

    # Add all environment variables to the tokens list
    # This is so that any can be used in substitutions in the generation of an AsciiDoc document
    $envs = Get-ChildItem -Path env:*
    foreach ($env in $envs) {
        $tokens[$env.Name] = $env.Value
    }

    # Perform the appropriate action based on the Parameter Set Name that
    # has been selected
    switch ($PSCmdlet.ParameterSetName) {
        "pdf" {

            # set the correct asciidoc command
            $cmdline += "asciidoctor-pdf"
            $extension = ".pdf"
        }

        "html" {
            $cmdline += "asciidoctor"
            $extension = ".html"
        }
    }

    # Read in the configuration file, if one has been specified
    if (Test-Path -Path $config) {
        # Read in the config using and merge with the empty settings hashtable
        $data = Get-Content -Path $config -Raw | ConvertFrom-Json -AsHashtable
        $settings = Merge-Hashtables -Primary $data -Secondary $settings
    }

    # If any attributes have been set, update the settings with them
    if ($attributes.count -gt 0) {
        $settings.$($PSCmdlet.ParameterSetName).attributes = $attributes
    }


    # if any attributes have been set, iterate around them and add the correct args and ensure any tokens have
    # been replaced
    foreach ($attr in $settings.$($PSCmdlet.ParameterSetName).attributes) {

        # Replace any values in the attribute
        $_attr = Replace-Tokens -tokens $tokens -data $attr

        $cmdline += '-a {0}' -f $_attr
    }

    # If any libraries have been specified add them to the command line as well
    if ($settings.libs.count -gt 0) {
        $cmdline += '-r {0}' -f ($settings.libs -join ",")
    }

    # Handle scenario where the output filename has been specified on the command line
    # this will then override the title and the output in the tokens
    if (![String]::IsNullOrEmpty($output)) {
        $settings.title = Split-Path -Path $output -Leaf
        $settings.output = Split-Path -Path $output -Parent
    }

    # Determine if the extension needs to be set on the filename
    if ($settings.title.EndsWith($extension)) {
        $extension = ""
    }

    if (![String]::IsNullOrEmpty($path)) {
        $settings.path = $path
    }

    # Ensure the tokens are replaced the settings
    $settings.output = Replace-Tokens -Tokens $tokens -Data $settings.output
    $settings.path = Replace-Tokens -Tokens $tokens -Data $settings.path
    $settings.title = Replace-Tokens -Tokens $tokens -Data $settings.title

    # Ensure that the path exists, if it does not error out
    if (!(Test-Path -Path $settings.path)) {
        Stop-Task -Message ("Specified path does not exist: {0}" -f $settings.path)
        return
    }

    # Update the cmdline with the arguments for the specifying the output filename
    $cmdline += '-o "{0}{1}"' -f $settings.title, $extension
    $cmdline += '-D "{0}"' -f $settings.output

    Write-Information -MessageData ("Output directory: {0}" -f $settings.output) -InformationAction Continue

    # Ensure that the output directory exists
    if (!(Test-Path -Path $settings.output)) {
        Write-Information -MessageData "Creating output directory" -InformationAction Continue
        New-Item -ItemType Directory -Path $settings.output | Out-Null
    }

    # Stitch the full command together
    $cmd = "{0} {1} {2}" -f ($cmdline -join " "), (Replace-Tokens -Tokens $tokens $settings.path), "--failure-level ${failureLevel}"

    # Execute the command
    Invoke-External -Command $cmd -AdditionalExitCodes $ExitCodes

    # Output the exitcode of the command
    $LASTEXITCODE
}
