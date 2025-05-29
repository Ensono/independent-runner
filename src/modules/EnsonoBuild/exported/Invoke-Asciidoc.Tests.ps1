Describe "Invoke-Asciidoc" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Invoke-Asciidoc.ps1

        # Import the dependenices for the function under test
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../exported/Invoke-External.ps1
        . $PSScriptRoot/../utils/Merge-Hashtables.ps1
        . $PSScriptRoot/../utils/Copy-Object.ps1
        . $PSScriptRoot/../exported/Stop-Task.ps1
        . $PSScriptRoot/../utils/Replace-Tokens.ps1
        . $PSScriptRoot/../utils/Set-Tokens.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

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
                dryrun   = $true
            }

            # Create a splat to pass to the cmdlet
            $splat = @{
                Format     = "docbook"
                Path       = "$testfolder/index.adoc"
                Output     = "${testfolder}/newsletter.xml"
                Libraries  = $Libraries
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
            $session.commands.list[0] | Should -Match ([Regex]::Escape('-o "{0}/newsletter.xml"' -f $testFolder))
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
                dryrun   = $true
            }

            Invoke-Asciidoc -Format pdf -path $testfolder -output "${testfolder}/newsletter.pdf"

            $Session.commands.list[0] | Should -BeLike ("*asciidoctor-pdf* -o `"{0}/newsletter.pdf`"" -f $testFolder)

            Should -Invoke -CommandName Write-Information -Times 1
        }

        it "will generate a PDF with attributes" {

            # Create attributes array
            $attributes = @(
                "allow-read-uri",
                "pdf-fontsdir=/fonts",
                "stackscli_version={{ BUILDNUMBER }}"
            )

            Invoke-Asciidoc -Format pdf -path $testfolder -output "${testfolder}/newsletter.pdf" -attributes $attributes

            $Session.commands.list[0] | Should -BeLike ("*asciidoctor-pdf* -o `"{0}/newsletter.pdf`"" -f $testFolder) #-a allow-read-uri -a pdf-fontsdir=/fonts -a stackscli_version=74.83.10.13 -o `"newsletter.pdf`" -D `"$testfolder`" $testfolder --failure-level warn"

            Should -Invoke -CommandName Write-Information -Times 1
        }
    }
}
