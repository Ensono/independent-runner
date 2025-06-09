
function Build-Documentation {

    [CmdletBinding()]
    param (

        [string]
        # Base path from which all paths will be derived
        # By default this will be the current directory, but in docker this should be the dir
        # that the directory is mapped into
        $Basepath = $(Get-Location),

        [string]
        [Alias("BuildNumber")]
        # Version number to apply to the generated documentation
        $Version = $(if ([String]::IsNullOrEmpty($env:BUILDNUMBER)) { $env:VERSION } else { $env:BUILDNUMBER }),

        [string]
        [Parameter(
            ParameterSetName = "config"
        )]
        # Path to configuration file with all the necessary settings
        # If specified additional specific parameters are specifed, those values will 
        # override the ones in the configuration file
        $Config = $env:DOC_CONFIG_FILE,

        [string[]]
        #[Parameter(
        #    ParameterSetName = "type"
        #)]
        [ValidateSet("md", "pdf", "docx", "txt", "jira", "html")]
        # Format that the document should be generated in. This is used to genarate a document
        # in one format. If you wish to generate multiple formats, use the Config file option
        $Type,

        [string]
        [Parameter(
            ParameterSetName = "type"
        )]
        # Path to the AsciiDoc template to render
        $Path = $env:DOC_FILE,

        [string]
        [Parameter(
            ParameterSetName = "type"
        )]
        # Path to the output folder
        $Output = "output",

        [string]
        [Parameter(
            ParameterSetName = "type"
        )]
        # Title to be given to the file - this can have tokens
        $Title = $env:DOC_TITLE,

        [string[]]
        [Parameter(
            ParameterSetName = "type"
        )]
        # Attributes that need to be set when generating the document
        $ADocAttributes = @()
    )

    # Set the list of formats that are supported
    $required_formats = @()

    # Create an empty config hashtable to be used to grab the settings for the generation
    $settings = @{
        title       = ""
        output      = ""
        path        = ""
        trunkBranch = ""
        formats     = @()
        attributes  = @{
            asciidoc = @()
        }
        libs        = @{
            asciidoc = @()
            pandoc   = @()
        }
        pdf         = @{
            attributes = @{
                asciidoc = @()
                pandoc   = @()
            }
        }
        html        = @{
            attributes = @{
                asciidoc = @()
                pandoc   = @()
            }
        }
        docx        = @{
            attributes = @{
                asciidoc = @()
                pandoc   = @()
            }
        }
        md          = @{
            attributes = @{
                asciidoc = @()
                pandoc   = @()
            }
        }
        txt         = @{
            attributes = @{
                asciidoc = @()
                pandoc   = @()
            }
        }
    }

    # Ensure that the necessary values have been set, based on the paramater set that is being used
    
    switch ($PSCmdlet.ParameterSetName) {
        "config" {
            if (Test-Path -Path $Config) {
                # Read in the config using and merge with the empty settings hashtable
                $data = Get-Content -Path $Config -Raw | ConvertFrom-Json -AsHashtable

                # Configure the settings
                $settings = Merge-Hashtables -Primary $data -Secondary $settings
            }
            else {
                Write-Error "The configuration file specified does not exist: ${Config}"
                return
            }
        }
        "type" {

            # Build up an object that will be used to generate the document using the existing engine
            $settings.title = $Title
            $settings.path = $Path
            $settings.output = $Output

            if (![IO.Path]::IsPathRooted($settings.path)) {
                $settings.path = [IO.Path]::Combine($Basepath, $settings.path)
            }
        }
    }

    # Add the type to the Formats array
    $Formats = $settings.formats
    # If the type parameter is specified, then add it to the formats
    if ($Type -and $Type.Count -gt 0) {
        $Formats = @($Type)
    }
    
    # $Formats = @($Type)

    # Set the mapping of formats to the BACKEND required for asciidoctor
    $format_mapping = @{
        "md"   = @{
            commands  = [ordered]@{
                "asciidoctor" = @{
                    format = "docbook"
                }
                "pandoc"      = @{
                    from = "docbook"
                    to   = "gfm"
                }
            }
            extension = @{
                "asciidoctor" = ".xml"
                "pandoc"      = ".md"
            }
        }
        "txt"  = @{
            commands  = [ordered]@{
                "asciidoctor" = @{
                    format = "docbook"
                }
                "pandoc"      = @{
                    from = "docbook"
                    to   = "plain"
                }
            }
            extension = @{
                "asciidoctor" = ".xml"
                "pandoc"      = ".txt"
            }
        }
        "pdf"  = @{
            commands  = [ordered]@{
                "asciidoctor" = @{
                    format = "pdf"
                }
            }
            extension = @{
                "asciidoctor" = ".pdf"
            }
        }
        "html" = @{
            commands  = [ordered]@{
                "asciidoctor" = @{
                    format = "html"
                }
            }
            extension = @{
                "asciidoctor" = ".html"
            }
        }
        "docx" = @{
            commands  = [ordered]@{
                "asciidoctor" = @{
                    format = "docbook"
                }
                "pandoc"      = @{
                    from = "docbook"
                    to   = "docx"
                }
            }
            extension = @{
                "asciidoctor" = ".xml"
                "pandoc"      = ".docx"
            }
        }
        "jira" = @{
            commands  = [ordered]@{
                "asciidoctor" = @{
                    format = "docbook"
                }
                "pandoc"      = @{
                    from = "docbook"
                    to   = "jira"
                }
            }
            extension = @{
                "asciidoctor" = ".xml"
                "pandoc"      = ".jira"
            }
        }
    }

    # Detremine the supported formats from the mappings
    $supported_formats = $format_mapping.Keys

    # Check that the format is supported
    foreach ($format in $Formats) {
        if ($supported_formats -notcontains $format) {
            Write-Warning ("The format '{0}' is not supported, and will be skipped" -f $format)
        }
        else {
            $required_formats += $format
        }
    }
    
    # Iterate around the formats and build up the commands that need to be run
    # The commands will be added to a list and executed in turn
    foreach ($format in $required_formats) {
        
        # Set a variable to hold the previous filename, this is so that it can be passed to the
        # next command in the chain for the format
        $previous_filename = ""

        # Get all the tokens that are available
        $tokens = Set-Tokens -Version $Version -ExtraTokens @{"basepath" = $Basepath; "format" = $format }

        # Ensure the tokens are replaced the settings
        $settings.path = Replace-Tokens -Tokens $tokens -Data $settings.path
        $settings.title = Replace-Tokens -Tokens $tokens -Data $settings.title
        
        # Determine if the settings.path is a single file or a directory
        # If single fil add to a single array, otherwise recursively find all *.adoc files in the folder
        if (Test-Path -Path $settings.path -PathType Leaf) {
            $files = @($settings.path)
        }
        else {
            $files = Get-ChildItem -Path $settings.path -Recurse -Filter "*.adoc" | Select-Object -ExpandProperty FullName
        }
        
        # Determine the name of the file
        $filename = $settings.title
        
        # iterate around the files that have been found
        foreach ($input_file in $files) {

            $previous_filename = ""
            
            # iterate around the command hashtable to build up the commands to run
            foreach ($h in $format_mapping[$format].commands.GetEnumerator()) {

                $arguments = @()

                $output = Replace-Tokens -Tokens $tokens -Data $settings.output

                # determine the output filename, this is based on there being several files or just one
                if ($files.count -eq 1) {
                    $output_path = "{0}{1}" -f [IO.Path]::Combine($output, $filename), $format_mapping[$format].extension[$h.Name]
                }
                elseif ($files.count -gt 1) {
                    $output_path = "{0}{1}" -f [IO.Path]::Combine($output, [IO.Path]::GetFileNameWithoutExtension($input_file)), $format_mapping[$format].extension[$h.Name]
                }

                # Ensure the parent path for the output file exists
                $output_parent_path = Split-Path -Path $output_path -Parent
                if (!(Test-Path -Path $output_parent_path)) {
                    Write-Information ("Creating output directory: {0}" -f $output_parent_path)
                    New-Item -Path $output_parent_path -ItemType Directory -Force | Out-Null
                }
                
                # switch on the command to determine which arguments to add
                switch -Wildcard ($h.Name) {
                    "asciidoctor*" {

                        # $input_file = $settings.path
                        if (![String]::IsNullOrEmpty($previous_filename)) {
                            $input_file = $previous_filename
                        }

                        # Merge top-level command attributes with the format specific attributes
                        $attributes = $settings.attributes.asciidoctor

                        if ($settings.$format.attributes.asciidoctor.length -gt 0) {
                            $attributes += $settings.$format.attributes.asciidoctor
                        }

                        # Determine if any attributes have been specifed on the command line, if they have
                        # add them to the attributes list
                        if ($ADocAttributes.Count -gt 0) {
                            $attributes += $ADocAttributes
                        }

                        $attributes = Replace-Tokens -tokens $tokens -data $attributes

                        # Create the splat for the Invoke-Asciidoc function
                        $splat = @{
                            Format     = $format_mapping[$format].commands.asciidoctor.format
                            Output     = $output_path
                            Path       = $input_file
                            Libraries  = $settings.libs["asciidoc"]
                            Attributes = $attributes
                        }

                        Invoke-AsciiDoc @splat
                        
                        $previous_filename = $output_path
                    }

                    "pandoc" {

                        # $input_file = $settings.path
                        if (![String]::IsNullOrEmpty($previous_filename)) {
                            $input_file = $previous_filename
                        }

                        # Ensure that the resource-dir is set so that images can be found
                        $attributes = Replace-Tokens -tokens $tokens -data $settings.$format.attributes.pandoc

                        # Determine the reference path
                        $resourcePath = $settings.Path
                        if (Test-Path -Path $resourcePath -PathType Leaf) {
                            $resourcePath = Split-Path -Path $resourcePath -Parent
                        }
                        $attributes += (" --resource-path=`"{0}`"" -f $resourcePath)

                        # Create the splat for the Invoke-Pandoc function
                        $splat = @{
                            From       = $format_mapping[$format].commands.pandoc.from
                            To         = $format_mapping[$format].commands.pandoc.to
                            Output     = $output_path
                            Path       = $input_file
                            Attributes = $attributes
                        }

                        Invoke-Pandoc @splat

                        # After invocation remove the previous filename so that it does not clutter up the output
                        Remove-Item -Path $previous_filename -Force

                        $previous_filename = $output_path
                    }
                }
            }
        }
    }
}
