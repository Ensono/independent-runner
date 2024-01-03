Describe "Build-Documenation" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Build-Documentation.ps1

        # Include depdendencies
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1
        . $PSScriptRoot/../utils/Protect-Filesystem.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../utils/ConvertTo-MDX.ps1

        # Mock commands
        Mock -CommandName Write-Error -MockWith {} -ParameterFilter { $Message.ToLower().Contains("documentation directory")}
        Mock -CommandName Write-Warning -MockWith {}
    }

    Context "will raise errors" {

        BeforeEach {
            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force
        }

        it "if docs directory does not exist" {

            Build-Documentation -BasePath $testFolder -Pdf

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Generate PDF documents" {

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
                dryrun = $true
            }
    
            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

            # Create the docs directory for eac test
            New-Item -ItemType Directory -Path (Join-Path -Path $testFolder -ChildPath "docs")

        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force | Out-Null
        }

        it "will build up command with a title" {

            Build-Documentation -BasePath $testFolder -Pdf -Title "Pester Tests"

            # Check the command that will be run
            $Session.commands.list[0] | Should -BeLike 'asciidoctor-pdf -o "Pester Tests.pdf" -D*/index.adoc'
        }

        it "will build up command with attributes" {

            Build-Documentation -BasePath $testFolder -Pdf -Title "Pester Tests" `
                                -Attributes "pdf-theme=styles/theme.yml", 'doctype="book"'

            # Check the command that will be run
            $Session.commands.list[0] | Should -BeLike 'asciidoctor-pdf -a pdf-theme=styles/theme.yml -a doctype="book" -o "Pester Tests.pdf" -D*/index.adoc'            
        }

        it "will build up attributes from a file" {

            # create the attributes file
            $attrFile = New-Item -ItemType File -Path ([io.path]::Combine($testFolder, "attrs.ps1"))
            Add-Content -Path $attrFile -Value @"
@(
    "-a pdf-theme=styles/theme.yml"
    "pdf-fonts=/app/docs/styles/fonts;GEM_FONTS_DIR"
)
"@

            Build-Documentation -BasePath $testFolder -Pdf -Title "Pester Tests" `
                -AttributeFile $attrFile.FullName

            # Check the command that will be run
            $Session.commands.list[0] | Should -BeLike 'asciidoctor-pdf -a pdf-theme=styles/theme.yml -a pdf-fonts=/app/docs/styles/fonts;GEM_FONTS_DIR -o "Pester Tests.pdf" -D*/index.adoc'
        }
    }

    Context "Generated MD files" {

        BeforeAll {

            # Mock the Find-Command cmdlet
            Mock -CommandName Find-Command -MockWith { "asciidoctor" } -ParameterFilter { $Name -eq "asciidoctor" }
            Mock -CommandName Find-Command -MockWith { "pandoc" } -ParameterFilter { $Name -eq "pandoc" }
            Mock -CommandName ConvertTo-MDX -MockWith {}
        }

        BeforeEach {

            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }
    
            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

            # Create the folder for the docs
            $docsDir = New-Item -ItemType Directory -Path (Join-Path -Path $testFolder -ChildPath "docs")

            # create an adoc file
            New-Item -ItemType File -Path (Join-Path -Path $docsDir.FullName -ChildPath "index.adoc")
        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force | Out-Null
        }
        
        It "will run the commands to generate a MD file" {

            Build-Documentation -BasePath $testFolder -MD -MDX

            $Session.commands.list[0] | Should -BeLike 'asciidoctor -b docbook -o *.xml *.adoc'
            $Session.commands.list[1] | Should -BeLike 'pandoc -f docbook -t gfm --wrap none *.xml -o *.md'

            # Check that the MDX file would be created
            Should -Invoke -CommandName ConvertTo-MDX -Times 1
        }        
    }


}
