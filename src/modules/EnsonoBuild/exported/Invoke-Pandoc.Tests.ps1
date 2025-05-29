Describe "Invoke-Pandoc" {

    BeforeAll {
        # Import the function under test
        . $PSScriptRoot/Invoke-Pandoc.ps1

        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/Invoke-External.ps1
        . $PSScriptRoot/../utils/Replace-Tokens.ps1
        . $PSScriptRoot/../utils/Set-Tokens.ps1

        # set an environment variable
        $env:REFERENCE_DOC = "reference.docx"

        # Set some attributes to be applied
        $Attributes = @("--reference-doc={{ REFERENCE_DOC }}")

        # Mock functions that are called
        # - Find-Command - return the name of the command that is required
        Mock -Command Find-Command -MockWith { return $name }

    }

    Context "Arguments" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                From       = "docbook"
                To         = "docx"
                Path       = "$testfolder/index.xml"
                Output     = "${testfolder}/newsletter.docx"
                Attributes = $Attributes
            }

            Invoke-Pandoc @splat
        }

        it "will use the correct command" {
            $Session.commands.list[0] | Should -Match "pandoc"
        }

        it "will add in the correct attributes" {
            $Session.commands.list[0] | Should -Match "--reference-doc=reference.docx"
        }
    }

    Context "Word document" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                From       = "docbook"
                To         = "docx"
                Path       = "$testfolder/index.xml"
                Output     = "${testfolder}/newsletter.docx"
                Attributes = $Attributes
            }

            Invoke-Pandoc @splat
        }

        it "will use the correct input format" {
            $Session.commands.list[0] | Should -Match "-f docbook"
        }

        it "will set the correct output format" {
            $Session.commands.list[0] | Should -Match "-t docx"
        }

        it "will set the correct output file" {
            $Session.commands.list[0] | Should -Match "-o `"$testfolder/newsletter.docx`""
        }
    }

    Context "MD document" {

        BeforeAll {
            # Create a session object so that the Invoke-External function does not
            # execute any commands but the command that would be run can be checked
            $global:Session = @{
                commands = @{
                    list = @()
                }
                dryrun   = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                From       = "docbook"
                To         = "gfm"
                Path       = "$testfolder/index.xml"
                Output     = "${testfolder}/newsletter.md"
                Attributes = $Attributes
            }

            Invoke-Pandoc @splat
        }

        it "will use the correct input format" {
            $Session.commands.list[0] | Should -Match "-f docbook"
        }

        it "will set the correct output format" {
            $Session.commands.list[0] | Should -Match "-t gfm"
        }

        it "will set the correct output file" {
            $Session.commands.list[0] | Should -Match "-o `"$testfolder/newsletter.md`""
        }
    }    
}