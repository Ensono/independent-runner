
Describe "Set-Config" {

    BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1


        # Include the function under test
        . $PSSCriptRoot/Set-Config.ps1

        $global:Session = @{
            commands = @{
                list = @()
                file = ""
            }
            dryrun   = $true
        }

        # Mock commands
        # Write-Error - so that when a function cannot find what it requires, the
        # error is generates can be caught
        Mock -CommandName Write-Error -MockWith { }
    }

    Context "Parent path for log file does not exist" {

        It "will error" {
            Set-Config -CommandPath (Join-Path -Path "does" -ChildPath "notexist")

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Log path is valid" {

        BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1

            
            # Create the testFolder
            $testFolder = New-TestDir

            $cmdLogFile = [IO.Path]::Combine($testFolder, "cmdlog.txt")
        }

        It "will configure the session" {

            Set-Config -CommandPath $cmdLogFile

            $session.commands.file | Should -Be $cmdLogFile
        }
    }
}

