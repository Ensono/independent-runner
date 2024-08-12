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

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Create a settings file to be used to create the document
        $settings = @{
            title = "Pester Newsletter"
            output = $testfolder
            path = $testfolder
            pdf = @{
                attributes = @(
                    "allow-read-uri"
                )
            }
        }
        $settings_file = [IO.Path]::Combine($testfolder, "settings.json")
        Set-Content -Path $settings_file -Value ($settings | ConvertTo-Json) | Out-Null

        $env:BUILDNUMBER = "74.83.10.13"

        # Mock functions that are called
        # - Find-Command - return the name of the command that is required
        Mock -Command Find-Command -MockWith { return $name }

        # - Write-Information - mock this internal function to check that the working directory is being defined
        Mock -Command Write-Information -MockWith { return $MessageData } -Verifiable
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
    }

    Context "PDF" {

        it "will generate the PDF" {

            Invoke-Asciidoc -pdf -path $testfolder -output "${testfolder}/newsletter.pdf"

            $Session.commands.list[0] | Should -BeLike "*asciidoctor-pdf* -o `"newsletter.pdf`" -D `"$testfolder`" $testfolder"

            Should -Invoke -CommandName Write-Information -Times 1
        }

        it "will generate a PDF with attributes" {

            # Create attributes array
            $attributes = @(
                "allow-read-uri",
                "pdf-fontsdir=/fonts",
                "stackscli_version={{ BUILDNUMBER }}"
            )

            Invoke-Asciidoc -pdf -path $testfolder -output "${testfolder}/newsletter.pdf" -attributes $attributes

            $Session.commands.list[0] | Should -BeLike "*asciidoctor-pdf* -a allow-read-uri -a pdf-fontsdir=/fonts -a stackscli_version=74.83.10.13 -o `"newsletter.pdf`" -D `"$testfolder`" $testfolder"

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "will use a settings file" {

            Invoke-AsciiDoc -pdf -basepath $testfolder -config $settings_file

            $Session.commands.list[0] | Should -BeLike "*asciidoctor-pdf* -a allow-read-uri -o `"Pester Newsletter.pdf`" -D `"$testfolder`" $testfolder"

            Should -Invoke -CommandName Write-Information -Times 1
        }
    }
}
