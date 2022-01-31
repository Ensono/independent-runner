
function Build-Documentation() {

    <#
    
    .SYNOPSIS
    Build documentation in a project in different formats

    .DESCRIPTION
    The Build-Docs cmdlet is used to generate documentation from the Asciidoc source in a project.

    The cmdlet allows for PDF and MD files to be generated.

    .NOTES

    In order for the documenation to be generated the asciidoctor, asciidoctor-pdf and pandoc binaries
    must be available. These can be installed locally or run in a container. 

    #>

    [CmdletBinding()]
    param (

        [string]
        # Application or base path from which the docs can be found
        $basePath = (Get-Location),

        [string]
        # Docs directory beneath the base path
        $docsDir = "docs",

        [Alias("target")]
        [string]
        # Output directory for the documentation
        $outputDir = "outputs",

        [string]
        # Set the build number to be applied to the documenation
        $buildNumber = $env:BUILDNUMBER,

        [Parameter(
            ParameterSetName="pdf"
        )]
        [switch]
        # State if PDF documentation should be generated
        $pdf,

        [Parameter(
            ParameterSetName="pdf"
        )]
        [string[]]
        # Attributes that should be passed to the generation of the PDF
        $attributes,

        [Parameter(
            ParameterSetName="pdf"
        )]
        [string]
        # Path to file containing attribuites that are required for the PDF creation
        $attributeFile,        

        [Parameter(
            ParameterSetName="pdf"
        )]
        [string]
        # Title of the PDF document
        $title,

        [Parameter(
            ParameterSetName="pdf"
        )]
        [string]
        # Name of file that should be used to generate the document
        # This is likely an indesx file that contains links to the other files to be included
        $indexFile = "index.adoc",        

        [Parameter(
            ParameterSetName="md"
        )]
        [switch]
        # State if markdown should be generated
        $md,

        [Parameter(
            ParameterSetName="md"
        )]
        [switch]
        # state if the MDX flavour of MD needs to be created
        $mdx
    )

    # Determine the directories
    # - raw documentation dir
    $docsDir = [IO.Path]::Combine($basePath, $docsDir)

    # - output directory
    $outputDir = Protect-Filesystem -Path $outputDir -BasePath (Get-Location).Path
    if (!$outputDir) {
        return $false
    }

    # Check that the documentation directory exists
    if (!(Test-Path -Path $docsDir)) {
        Write-Error -Message ("Documentation directory does not exist: {0}" -f $docsDir)
        return $false
    }

    # generate the documentation based on the switch that has been specified
    switch ($PSCmdlet.ParameterSetName) {
        "pdf" {

            # determine the pdf output dir and create if it does not exist
            $pdfOutputDir = [IO.Path]::Combine($outputDir, "docs", "pdf")
            if (!(Test-Path -Path $pdfOutputDir)) {
                Write-Output ("Creating output dir: {0}" -f $pdfOutputDir)
                New-Item -ItemType Directory -Path $pdfOutputDir | Out-Null
            }

            # Ensure that the command to generate the PDF can be found
            $pdfCommand = Find-Command -Name "asciidoctor-pdf"
            if ([string]::IsNullOrEmpty($pdfCommand)) {
                return
            }

            # Configure the attributes
            $attrs = @()

            # if an attribute file has been specified read trhe values from there
            if (![string]::IsNullOrEmpty($attributeFile)) {

                # check to see if the file exists
                if (Test-Path -Path $attributeFile) {

                    # get the file extension of the file to check that it is the correct format
                    $extn = [IO.Path]::GetExtension($attributeFile)

                    switch ($extn) {
                        ".ps1" {

                            # read the file into the attributes array
                            $attributes = Invoke-Expression -Command (Get-Content -Path $attributeFile -Raw)
                        }
                        default {
                            Write-Warning -Message "Specified file format is not supported"
                        }
                    }


                } else {

                    Write-Warning -Message ("Unable to find specified attributes file: {0}" -f $attributeFile)
                }
            }

            # configure the attributes correctly
            foreach ($attribute in $attributes) {
                
                # do not add the -a if it already starts with that
                $line = ""
                if ($attribute.StartsWith("-a")) {
                    $line = "{0}"
                } else {
                    $line = "-a {0}" 
                }

                $attrs += , $line -f $attribute
            }

            

            # Build up the array to hold the parts of the command to run
            $cmdParts = @(
                $pdfCommand
                $attrs
                '-o "{0}.pdf"' -f $title
                "-D {0}" -f $pdfOutputDir
                "{0}/{1}" -f $docsDir, $indexFile
            )

            # run the command by joining the command and then executing it
            $cmd = $cmdParts -join " "
            Invoke-External -Command $cmd

            Write-Information -Message ("Created PDF documentation: {0}.pdf" -f ([IO.Path]::Combine($pdfOutputDir, $title)))
        }

        "md" {

            # Create a temporary directory to store transitional XML files
            $mdOutputDir = [IO.Path]::Combine($outputDir, "docs", "md")
            if (!(Test-Path -Path $mdOutputDir)) {
                Write-Output ("Creating output dir: {0}" -f $mdOutputDir)
                New-Item -ItemType Directory -Path $mdOutputDir | Out-Null
            }

            $tempOutputDir = [IO.Path]::Combine($outputDir, "docs", "temp")
            if (!(Test-Path -Path $tempOutputDir)) {
                Write-Output ("Creating temporary output dir: {0}" -f $tempOutputDir)
                New-Item -ItemType Directory -Path $tempOutputDir | Out-Null
            }

            # Get a list of the document files
            $list = Get-ChildItem -Path $DocsDir/* -Attributes !Directory -Include *.adoc

            # Iterate around the list of files
            foreach ($item in $list) {

                # Get the name of the file from the pipeline
                $fileTitle = [System.IO.Path]::GetFileNameWithoutExtension($item.FullName)

                # define the filenames
                $xmlFile = [IO.Path]::Combine($tempOutputDir, ("{0}.xml" -f $fileTitle))
                $mdFile = [IO.Path]::Combine($mdOutputDir, ("{0}.md" -f $fileTitle))

                # Find the necessary commands
                $asciidoctorCmd = Find-Command -Name "asciidoctor"
                $pandocCmd = Find-Command -Name "pandoc"

                # build up the commands that need to be executed
                $commands = @()

                # -- convert to xml
                $commands += "{0} -b docbook -o {1} {2}" -f $asciidoctorCmd, $xmlFile, $item.FullName

                # -- convert XML to markdown
                $commands += "{0} -f docbook -t gfm --wrap none {1} -o {2}" -f $pandocCmd, $xmlFile, $mdFile

                Invoke-External -Command $commands

                Write-Information -MessageData ("Create Markdown file: {0}" -f $mdFile)

                # If the switch to generate MDX file has been set, execute it
                if ($MDX.IsPresent) {

                    # create the mdx file path
                    $mdxOutputDir = [IO.Path]::Combine($outputDir, "docs", "mdx")
                    $mdxFile = [IO.Path]::Combine($mdxOutputDir, ("{0}.mdx" -f $fileTitle))

                    ConvertTo-MDX -Path $mdFile -Destination $mdxFile
                }
            }

            # Remove the temporary directory
            Remove-Item -Path $tempOutputDir -Force -Recurse
        }
    }

}
