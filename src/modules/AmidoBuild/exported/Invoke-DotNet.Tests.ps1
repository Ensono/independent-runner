
Describe "Invoke-Dotnet" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Invoke-DotNet.ps1
    
        # Import the dependenices for the function under test
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../projects/Find-Projects.ps1
    
        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
    
        # Mock functions that are called
        # - Find-Command - return the name of the command that is required
        Mock -Command Find-Command -MockWith { return $name }
    
        # - Write-Information - mock this internal function to check that the working directory is being defined
        Mock -Command Write-Information -MockWith { return $MessageData } -Verifiable
    
        # - Write-Error - mock this internal function to check that errors are being raised
        Mock -Command Write-Error -MockWith { return $MessageData } -Verifiable
    
        # - Push-Location
        Mock -Command Push-Location
    
        # - Pop-Location
        Mock -Command Pop-Location
    
        # - Get-Location
        Mock -Command Get-Location -ParameterFilter { $stackName -eq "dotnet" } -MockWith { @("dummy") }
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

    Context "Build" {

        Context "run build without working directory" {

            It "will run a build in the current dir" {
    
                Invoke-DotNet -Build
    
                $Session.commands.list[0] | Should -BeLike "*dotnet* build"
    
                Should -Invoke -CommandName Write-Information -Times 1
                
            }
        }
    
        Context "run a build in a specified directory" {
    
            It "will specify a working directory" {
    
                Invoke-DotNet -Build -WorkingDirectory $testFolder
    
                Should -Invoke -CommandName Write-Information -Times 1
                Should -Invoke -CommandName Push-Location -Times 1
                Should -Invoke -CommandName Pop-Location -Times 1
    
            }
        }
    }

    Context "Coverage" {

        BeforeAll {

            # Create dummy coverage file in the testfolder
            New-Item -ItemType File -Path (Join-Path -Path $testFolder -ChildPath "pester.opencover.xml")
            New-Item -ItemType File -Path (Join-Path -Path $testFolder -ChildPath "pester.otherfile.xml")
        }

        It "will error as no coverage files can be found" {

            Invoke-DotNet -Coverage

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will run coverage command for all files that it finds" {

            # Call the dotnet function
            Invoke-DotNet -Coverage -Path $testFolder

            $Session.commands.list[0] | Should -BeLike "*reportgenerator* -reports:*pester.opencover.xml* -targetdir:coverage -reporttypes:Cobertura"
        }

        It "will run coverage for specified pattern" {

            # Call the dotnet function
            Invoke-DotNet -Coverage -Path $testFolder -Pattern "*.otherfile.xml"

            $Session.commands.list[0] | Should -BeLike "*reportgenerator* -reports:*otherfile.xml* -targetdir:coverage -reporttypes:Cobertura"

        }
    }

    Context "Custom" {

        It "will error if no arguments have been specified" {
            Invoke-DotNet -Custom

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will run the dotnet command with the specified arguments" {
            Invoke-DotNet -Custom -Arguments "clean"

            $Session.commands.list[0] | Should -BeLike "*dotnet* clean"
        }
    }

    Context "Tests" {

        Context "Without test files" {

            It "will error as no pattern has been specified" {
                Invoke-DotNet -Tests

                Should -Invoke -CommandName Write-Error -Times 1
            }

            It "will error as no files can be found that match the pattern" {
                Invoke-DotNet -Tests -Pattern "dummy"

                Should -Invoke -CommandName Write-Error -Times 1
            }
        }

        Context "With test files" {

            BeforeAll {

                # create some tests files for the function to find
                foreach ($file in @("pester1.UnitTests.csproj", "pester2.UnitTests.csproj", "pester3.UnitTests.csproj")) {
                    New-Item -ItemType File -Path (Join-Path -Path $testFolder -ChildPath $file)
                }
            }

            It "will execute tests for each project" {

                Invoke-DotNet -Tests -Path $testFolder -Pattern "*UnitTests*"

                $Session.commands.list.Count | Should -Be 3

                $Session.commands.list[0] | Should -BeLike "*dotnet* test *pester1.UnitTests.csproj"
            }

            It "will append arguments to the command" {

                Invoke-DotNet -Tests -Path $testFolder -Pattern "*UnitTests*" -Arguments "--no-restore"

                $Session.commands.list.Count | Should -Be 3

                $Session.commands.list[0] | Should -BeLike "*dotnet* test *pester1.UnitTests.csproj --no-restore"
            }
        }
    }
    

}