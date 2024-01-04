
Describe "Set-Config" {

    BeforeAll {

        # Include the function under test
        . $PSSCriptRoot/Set-Config.ps1

        $global:Session = @{
            commands = @{
                list = @()
                file = ""
            }
            dryrun = $true
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
            
            # Create the testFolder
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

            $cmdLogFile = [IO.Path]::Combine($testFolder, "cmdlog.txt")
        }

        It "will configure the session" {

            Set-Config -CommandPath $cmdLogFile

            $session.commands.file | Should -Be $cmdLogFile
        }
    }
}