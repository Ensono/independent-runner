
Describe "Invoke-External" {

    BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1


        # Import function under test
        . $PSScriptRoot/Invoke-External.ps1

        # Import dependent functions
        . $PSScriptRoot/Stop-Task.ps1

        # Import dependent classes
        . $PSScriptRoot/../classes/StopTaskException.ps1

        # Create the testFolder
        $testFolder = New-TestDir

        # Mocks
        # Invoke-Expression - mock the command that runs the command
        Mock -CommandName Invoke-Expression -MockWith {}

    }

    Context "[DRYRUN] Command file" {

        BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1


            $cmdlogPath = [IO.Path]::Combine($testFolder, "cmdlog.txt")

            # Define the session variable
            # Set the command log file and all commands are run in dryrun
            $global:Session = @{
                commands = @{
                    list = @()
                    file = $cmdLogPath
                }
                dryrun = $true
            }
        }

        AfterAll {
            Remove-Variable -Name Session -Scope global
        }

        It "writes commands to a file" {

            Invoke-External -Command @("docker build")

            Test-Path -Path $cmdLogPath | Should -Be $true

            Should -Invoke -Command Invoke-Expression -Times 0
        }
    }

    Context "Multiple commands" {

        BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1

            # Define the session variable
            # Set the command log file
            $global:Session = @{
                commands = @{
                    list = @()
                }
            }

            Mock `
                -Command Write-Host `
                -MockWith {}
        }

        It "are run" {

            # build up array of commands to run
            $cmds = @(
                "docker build"
                "dotnet build",
                "terraform plan"
            )

            Invoke-External -Commands $cmds

            Should -Invoke -Command Invoke-Expression -Times 3

            # Check that there are all the commands in the list
            $global:Session.commands.list.count | Should -Be 3
        }
    }
}

