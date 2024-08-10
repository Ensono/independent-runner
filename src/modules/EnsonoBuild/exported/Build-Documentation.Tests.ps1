
Describe "Build-Documentation" {

    BeforeAll {

        $relativePath = ".."

        # Include function under test
        . $PSScriptRoot/Build-Documentation.ps1

        # Include dependencies
        . $PSScriptRoot/Invoke-AsciiDoc.ps1
        . $PSScriptRoot/Invoke-Pandoc.ps1
        . $PSScriptRoot/$relativePath/command/Invoke-External.ps1
        . $PSScriptRoot/$relativePath/utils/Merge-Hashtables.ps1
        . $PSScriptRoot/$relativePath/utils/Copy-Object.ps1
        . $PSScriptRoot/$relativePath/utils/Replace-Tokens.ps1
        . $PSScriptRoot/$relativePath/utils/Set-Tokens.ps1

        # Determine the separator for the test evnrionment
        $separator = [IO.Path]::DirectorySeparatorChar
        $separator = $separator -replace '\\', '\\'

        # Create a folder to use for each test
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Escape the test folder separator if necessary
        $testFolder = $testFolder -replace '\\', '\\'

        # Create the docs directory for each test
        New-Item -ItemType Directory -Path (Join-Path -Path $testFolder -ChildPath "docs")

        # Create the configurtation file that is to be used
        $config = @"
{
    "title": "Infrastructure Testing - {{ version }}",
    "output": "{{ basepath }}/output",
    "trunkBranch": "main",
    "path": "{{ basepath }}/docs/infratesting/index.adoc",
    "libs": ["asciidoctor-diagram"],
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
            $configFile = Join-Path -Path $testFolder -ChildPath "config.json"
            Set-Content -Path $configFile -Value $config

            # - Find-Command - return the name of the command that is required
            Mock -Command Find-Command -MockWith { return $name }
    }

    AfterAll {

        Remove-Item -Path $testFolder -Recurse -Force | Out-Null
    }    

    Context "Generate PDF document with config" {

        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            Build-Documentation -Format "pdf" -Basepath $testFolder -Config $configFile -Version "1.2-pester"
        }

        it "will generate the document using the correct command" {

            # - should be using the asciidoctor-pdf command
            $Session.commands.list[0] | Should -Match 'asciidoctor-pdf*'
        }

        it "will create a document with a version number" {

            # - should set the filename correctly
            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.pdf"' -f $testFolder, $separator
            $Session.commands.list[0] | Should -Match $pattern
        }

        it "will use the correct libraries" {

            $Session.commands.list[0] | Should -Match "-r asciidoctor-diagram"
        }

        it "will add in all the specifed attributes" {

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

    Context "Generate PDF document using parameters" {
        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            Build-Documentation -Type "pdf" -Basepath $testFolder -Title "Pester Test" -Version "1.2-pester" -Path "{{ basepath }}/docs/infratesting/index.adoc"
        }

        it "will generate the document using the correct command" {

            # - should be using the asciidoctor-pdf command
            $Session.commands.list[0] | Should -Match 'asciidoctor-pdf*'
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
                dryrun = $true
            }

            Build-Documentation -Format "docx" -Basepath $testFolder -Config $configFile -Version "1.2-pester"
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
            $Session.commands.list[1] | Should -Match '-f docbook -t docx'
        }

        it "will create a document with a version number" {

            # - should set the filename correctly
            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.xml"' -f $testFolder, $separator
            $Session.commands.list[0] | Should -Match $pattern

            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.docx"' -f $testFolder, $separator
            $Session.commands.list[1] | Should -Match $pattern
        }

        it "will use the correct reference document" {

            $Session.commands.list[1] | Should -Match "--reference-doc=references.docx"
        }
    }

    Context "Generate MD document" {

        BeforeAll {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            Build-Documentation -Format "md" -Basepath $testFolder -Config $configFile -Version "1.2-pester"
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
            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.xml"' -f $testFolder, $separator
            $Session.commands.list[0] | Should -Match $pattern

            $pattern = '-o "{0}{1}output/|\\Infrastructure Testing - 1.2-pester.md"' -f $testFolder, $separator
            $Session.commands.list[1] | Should -Match $pattern
        }
    }    
}