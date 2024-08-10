Describe "Invoke-Asciidoc" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Invoke-Asciidoc.ps1
    
        # Import the dependenices for the function under test
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../utils/Replace-Tokens.ps1
        . $PSScriptRoot/../utils/Set-Tokens.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Escape the test folder separator if necessary
        $matchFolder = $testFolder -replace '\\', '\\'

        # Set the libs that need to be applied
        $Libraries = @("asciidoctor-diagram")
        
        # Set some attributes to be applied
        $Attributes = @("allow-uri-read", "java=/usr/bin/java")

        # Mock functions that are called
        # - Find-Command - return the name of the command that is required
        Mock -Command Find-Command -MockWith { return $name }

        # - Write-Information - mock this internal function to check that the working directory is being defined
        Mock -Command Write-Information -MockWith { return $MessageData } -Verifiable
    }

    Context "Arguments" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                Format = "docbook"
                Path = "$testfolder/index.adoc"
                Output = "${testfolder}/newsletter.xml"
                Libraries = $Libraries
                Attributes = $Attributes
            }
            Invoke-Asciidoc @splat
        }

        it "will add in libraries to be used" {
            $Session.commands.list[0] | Should -Match "-r asciidoctor-diagram"
        }

        it "will add in all the attributes" {
            $Session.commands.list[0] | Should -Match "-a allow-uri-read"
            $Session.commands.list[0] | Should -Match "-a java=/usr/bin/java"
        }

        it "all generated files will be written to the output directory" {
            $Session.commands.list[0] | Should -Match "-D `"$matchFolder`""
        }
    }

    Context "Docbook" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                Format = "docbook"
                Path = "$testfolder/index.adoc"
                Output = "${testfolder}/newsletter.xml"
                Libraries = $Libraries
                Attributes = $Attributes
            }
            Invoke-Asciidoc @splat
        }

        it "will use the correct command" {
            $Session.commands.list[0] | Should -Match "asciidoctor"
        }

        it "will use the correct output format" {
            $Session.commands.list[0] | Should -Match "-b docbook5"
        }

        it "will write to the correct file" {
            # Ensure that the command is correct
            $Session.commands.list[0] | Should -Match "-o `"$matchFolder/newsletter.xml`""
        }
    }

    Context "HTML" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                Format = "html"
                Path = "$testfolder/index.adoc"
                Output = "${testfolder}/newsletter.html"
                Libraries = $Libraries
                Attributes = $Attributes
            }
            Invoke-Asciidoc @splat
        }

        it "will use the correct command" {
            $Session.commands.list[0] | Should -Match "asciidoctor"
        }

        it "will use the correct output format" {
            $Session.commands.list[0] | Should -Match "-b html5"
        }

        it "will write to the correct file" {
            # Ensure that the command is correct
            $Session.commands.list[0] | Should -Match "-o `"$matchFolder/newsletter.html`""
        }
    }

    Context "PDF" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun = $true
            }

            Invoke-Asciidoc -Format pdf -Path "$testfolder/index.adoc" -Output "${testfolder}/newsletter.pdf"
        }

        it "will use the correct command" {
            $Session.commands.list[0] | Should -Match "asciidoctor-pdf"
        }

        it "will write to the correct file" {
            # Ensure that the command is correct
            $Session.commands.list[0] | Should -Match "-o `"$matchFolder/newsletter.pdf`""
        }

    }
}