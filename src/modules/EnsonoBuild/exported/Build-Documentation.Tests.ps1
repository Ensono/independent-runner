



Describe "Build-Documentation" {

    BeforeAll {

        $relativePath = ".."

        # Include function under test
        . $PSScriptRoot/Build-Documentation.ps1

        # Include dependencies
        . $PSScriptRoot/Invoke-Asciidoc.ps1
        . $PSScriptRoot/Invoke-Pandoc.ps1

        . $PSScriptRoot/$relativePath/utils/Copy-Object.ps1
        . $PSScriptRoot/$relativePath/utils/Merge-Hashtables.ps1
        . $PSScriptRoot/$relativePath/utils/Replace-Tokens.ps1
        . $PSScriptRoot/$relativePath/utils/Set-Tokens.ps1

        # Determine the separator for the test evnrionment
        $osDirSeparator = [IO.Path]::DirectorySeparatorChar
        $separator = $osDirSeparator -replace '\\', '\\'

        ############################################################
        # Helper Functions
        ############################################################
        function Get-TestFolder() {
            $testFolderPath = "TestDrive:\folder"
            if (!(Test-Path -Path $testFolderPath)) {
                $testFolder = (New-Item $testFolderPath -ItemType Directory).FullName    
            }
            else {
                $testFolder = (Get-Item -Path $testFolderPath).FullName
            }

            return $testFolder
        }

        function Get-DocsPath($testFolder) {
            $docsPath = [IO.Path]::Combine($testFolder, "docs")
            if (!(Test-Path -Path $docsPath)) {
                # Create the docs directory for each test
                New-Item -ItemType Directory -Path $docsPath | Out-Null
            }

            return $docsPath
        }

        # Define the configuration file to use when generating documentation
        $config = @"
{
    "title": "Infrastructure Testing - {{ version }}",
    "output": "{{ basepath }}/output",
    "trunkBranch": "main",
    "path": "{{ basepath }}/docs/index.adoc",
    "libs": {"asciidoc": ["asciidoctor-diagram"]},
    "attributes": {
        "asciidoctor": [
            "allow-uri-read",
            "java=/usr/bin/java",
            "graphvizdot=/usr/bin/dot",
            "convert=/usr/bin/convert",
            "identify=/usr/bin/identify"
        ]
    },
    "pdf": {
        "attributes": {
            "asciidoctor": [
                "pdf-theme={{ basepath }}/conf/pdf/theme.yml",
                "pdf-fontsdir=\"{{ basepath }}/conf/fonts;GEM_FONTS_DIR\""
            ]
        }
    },
    "html": {
        "attributes": {
            "asciidoctor": [
                "stylesheet={{ basepath }}/conf/html/style.css",
                "toc=left"
            ]
        }
    },
    "docx": {
        "attributes": {
            "pandoc": ["--reference-doc=references.docx"]
        }
    }
}
"@        
    }

    Context "Generate PDF documents using the command line" {

        BeforeAll {

            # Mock the Find-Command cmdlet
            Mock -CommandName Find-Command -MockWith { "asciidoctor-pdf" }
        }

        BeforeEach {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            # Get the docs document path
            $testFolder = Get-TestFolder
            $docsPath = Get-DocsPath $testFolder

            $indexFile = New-Item -Type File -Path ([IO.Path]::Combine($docsPath, "index.adoc")) -Force

        }

        it "will build up a command with a title" {

            $splat = @{
                BasePath = $testFolder
                Type     = "pdf"
                Title    = "Pester Tests"
                Path     = [IO.Path]::Combine("docs", "index.adoc")
                Output   = "output"
            }

            Build-Documentation @splat

            # Check that the asciidoctor-pdf command was added to the session
            $expected = 'asciidoctor-pdf -o "{0}" {1}' -f [IO.Path]::Combine("output", "Pester Tests.pdf"), $indexFile.FullName
            $Session.commands.list[0] | Should -BeLike $expected
        }

        It "will build command with attributes" {

            $splat = @{
                BasePath       = $testFolder
                Type           = "pdf"
                Title          = "Pester Tests"
                Path           = [IO.Path]::Combine("docs", "index.adoc")
                Output         = "output"
                ADocAttributes = @("pdf-theme=styles/theme.yml", 'doctype="book"')
            }

            Build-Documentation @splat

            # Check that the asciidoctor-pdf command was added to the session
            $expected = 'asciidoctor-pdf -o "{0}" -a pdf-theme=styles/theme.yml -a doctype="book" {1}' -f [IO.Path]::Combine("output", "Pester Tests.pdf"), $indexFile.FullName
            $Session.commands.list[0] | Should -BeLike $expected
        }

    }

    Context "Generate PDF document with a configuration file" {

        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            $testFolder = Get-TestFolder
            $docsPath = Get-DocsPath $testFolder

            $indexFile = New-Item -Type File -Path ([IO.Path]::Combine($docsPath, "index.adoc")) -Force

            $configFile = [IO.Path]::Combine($testFolder, "config.json")
            Set-Content -Path $configFile -Value $config

            Mock -Command Find-Command -MockWith { return $name }

            # Call the command and then test the output in the session
            $splat = @{
                BasePath = $testFolder
                Type     = "pdf"
                Config   = $configFile
                Version  = "1.2-pester"
            }

            Build-Documentation @splat 
        }

        It "will call the PDF generation command" {
            $Session.commands.list[0] | Should -Match 'asciidoctor-pdf*'
        }

        It "will create a document with a version number in the file name" {

            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.pdf"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[0] | Should -Match $pattern
        }

        It "will use the correct libraries" {
            $Session.commands.list[0] | Should -Match "-r asciidoctor-diagram"
        }

        It "will add all the specified attributes" {
            $Session.commands.list[0] | Should -Match "-a allow-uri-read"
            $Session.commands.list[0] | Should -Match "-a java=/usr/bin/java"
            $Session.commands.list[0] | Should -Match "-a graphvizdot=/usr/bin/dot"
            $Session.commands.list[0] | Should -Match "-a convert=/usr/bin/convert"
            $Session.commands.list[0] | Should -Match "-a identify=/usr/bin/identify"

            $pattern = '-a pdf-theme={0}/conf/pdf/theme.yml' -f ($testFolder -replace "\\", "\\")
            $Session.commands.list[0] | Should -Match $pattern

            $pattern = 'pdf-fontsdir="{0}/conf/fonts;GEM_FONTS_DIR"' -f ($testFolder -replace "\\", "\\")
            $Session.commands.list[0] | Should -Match $pattern
        }
    }

    Context "Generate Word document" {

        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            $testFolder = Get-TestFolder
            $docsPath = Get-DocsPath $testFolder

            # Create the Index file so that the cmdlet has something to work with
            $indexFile = New-Item -Type File -Path ([IO.Path]::Combine($docsPath, "index.adoc")) -Force

            # Create the XML file which is the docbook output from asciidoctor, this is so that
            # the commands that are run can be checked
            $pandocFile = New-Item -Type File -Path ([IO.Path]::Combine($testFolder, [IO.Path]::Combine('output', 'Infrastructure Testing - 1.2-pester.xml'))) -Force

            $configFile = [IO.Path]::Combine($testFolder, "config.json")
            Set-Content -Path $configFile -Value $config

            Mock -Command Find-Command -MockWith { return $name }

            # Call the command and then test the output in the session
            $splat = @{
                BasePath = $testFolder
                Type     = "docx"
                Config   = $configFile
                Version  = "1.2-pester"
            }

            Build-Documentation @splat 
        }

        it "will generate the document using the correct commands" {

            # - should be using the asciidoctor-pdf command
            $Session.commands.list[0] | Should -Match 'asciidoctor'
            $Session.commands.list[1] | Should -Match 'pandoc'
        }

        it "will use the correct output format for asciidoctor" {
            $Session.commands.list[0] | Should -Match '-b docbook5'
        }

        it "will use the correct reference document" {

            $Session.commands.list[1] | Should -Match "--reference-doc=references.docx"
        }

        it "will create a document with a version number" {

            # - should set the filename correctly
            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.xml"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[0] | Should -Match $pattern

            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.docx"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[1] | Should -Match $pattern
        }        
    }

    Context "Generate MD file" {
        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            $testFolder = Get-TestFolder
            $docsPath = Get-DocsPath $testFolder

            # Create the Index file so that the cmdlet has something to work with
            $indexFile = New-Item -Type File -Path ([IO.Path]::Combine($docsPath, "index.adoc")) -Force

            # Create the XML file which is the docbook output from asciidoctor, this is so that
            # the commands that are run can be checked
            $pandocFile = New-Item -Type File -Path ([IO.Path]::Combine($testFolder, [IO.Path]::Combine('output', 'Infrastructure Testing - 1.2-pester.xml'))) -Force

            $configFile = [IO.Path]::Combine($testFolder, "config.json")
            Set-Content -Path $configFile -Value $config

            Mock -Command Find-Command -MockWith { return $name }

            # Call the command and then test the output in the session
            $splat = @{
                BasePath = $testFolder
                Type     = "md"
                Config   = $configFile
                Version  = "1.2-pester"
            }

            Build-Documentation @splat 
        }

        it "will generate the document using the correct commands" {

            # - should be using the asciidoctor-pdf command
            $Session.commands.list[0] | Should -Match 'asciidoctor'
            $Session.commands.list[1] | Should -Match 'pandoc'
        }

        it "will use the correct output format for asciidoctor" {
            $Session.commands.list[0] | Should -Match '-b docbook5'
        }

        it "will use the correct input and output arguments for pandoc" {
            $Session.commands.list[1] | Should -Match '-f docbook -t gfm'
        }

        it "will create a document with a version number" {

            # - should set the filename correctly
            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.xml"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[0] | Should -Match $pattern

            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.md"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[1] | Should -Match $pattern
        }        
    }

    Context "Generate Jira file" {
        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            $testFolder = Get-TestFolder
            $docsPath = Get-DocsPath $testFolder

            # Create the Index file so that the cmdlet has something to work with
            $indexFile = New-Item -Type File -Path ([IO.Path]::Combine($docsPath, "index.adoc")) -Force

            # Create the XML file which is the docbook output from asciidoctor, this is so that
            # the commands that are run can be checked
            $pandocFile = New-Item -Type File -Path ([IO.Path]::Combine($testFolder, [IO.Path]::Combine('output', 'Infrastructure Testing - 1.2-pester.xml'))) -Force

            $configFile = [IO.Path]::Combine($testFolder, "config.json")
            Set-Content -Path $configFile -Value $config

            Mock -Command Find-Command -MockWith { return $name }

            # Call the command and then test the output in the session
            $splat = @{
                BasePath = $testFolder
                Type     = "jira"
                Config   = $configFile
                Version  = "1.2-pester"
            }

            Build-Documentation @splat 
        }

        it "will generate the document using the correct commands" {

            # - should be using the asciidoctor-pdf command
            $Session.commands.list[0] | Should -Match 'asciidoctor'
            $Session.commands.list[1] | Should -Match 'pandoc'
        }

        it "will use the correct output format for asciidoctor" {
            $Session.commands.list[0] | Should -Match '-b docbook5'
        }

        it "will use the correct input and output arguments for pandoc" {
            $Session.commands.list[1] | Should -Match '-f docbook -t jira'
        }

        it "will create a document with a version number" {

            # - should set the filename correctly
            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.xml"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[0] | Should -Match $pattern

            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.jira"' -f ($testFolder -replace "\\", "\\"), $separator
            $Session.commands.list[1] | Should -Match $pattern
        }        
    }    
}
