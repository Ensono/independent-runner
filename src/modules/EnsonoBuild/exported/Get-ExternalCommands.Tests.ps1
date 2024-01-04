
 

Describe "Get-ExternalCommands" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Get-ExternalCommands.ps1
    
        # Write-Error - check that errors are bein raised appropriately
        Mock -Command Write-Error -MockWith { return $messageData } -Verifiable
    
        # Write-Warning - check that errors are bein raised appropriately
        Mock -Command Write-Warning -MockWith {} -Verifiable
    }      

    Context "No session is defined" {

        BeforeAll {
            Remove-Variable -Name Session -Scope global -ErrorAction SilentlyContinue
        }

        It "will error" {

            Get-ExternalCommands

            Should -Invoke -CommandName Write-Warning -Times 1
        }
    }

    Context "A session is defined" {

        Context "no commands have been run" {

            BeforeAll {

                # Create a session object so that the command list can be interrogated
                New-Variable -Name Session -Scope Global -Value @{
                    commands = @{
                        list = @()
                    }
                }
            }

            It "will provide a warning" {

                Get-ExternalCommands

                Should -Invoke -CommandName Write-Warning -Times 1
            }

            AfterAll {
                Remove-Variable -Name Session -Scope Global
            }
        }

        Context "commands have been executed" {

            BeforeAll {

                # Create a session object so that the command list can be interrogated
                New-Variable -Name Session -Scope Global -Value @{
                    commands = @{
                        list = @(
                            "dotnet build",
                            "terraform output -json"
                        )
                    }
                }
            }

            It "will return all commands" {

                $cmds = Get-ExternalCommands

                $cmds.Count | Should -Be 2
            }

            It "will return the specified command" {

                $cmd = Get-ExternalCommands -Item 2

                $cmd | Should -Be "terraform output -json"
            }

            It "will error if the specified item is greater than the number of commands" {

                Get-ExternalCommands -Item 3

                Should -Invoke -CommandName Write-Error -Times 1
            }

            AfterAll {
                Remove-Variable -Name Session -Scope Global
            }            
        }
    }
}