Describe "Build-DockerImage" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Build-DockerImage.ps1
    
        # Import dependencies that the function under test requires
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../cloud/Connect-Azure.ps1
    
        # Write function to mimic the Get-AzContainerRegistryCredential which is supplied
        # by the PowerShell AZ Module, but this might not be available in the test environment
        # The command is not loaded so it is not possible to mock it
        function Get-AzContainerRegistryCredential() {
            [CmdletBinding()]
            param (
                [string]
                $Name,
    
                [string]
                $ResourceGroup
            )
    
            return @{
                Username = "pester"
                Password = "pester123"
            }        
        }
    
        # Mock functions that are called
        # - Find-Command - return "docker" as the command withouth looking at the filesystem as Docker may
        #                  not exist in the testing environment
        Mock -Command Find-Command -MockWith { return "docker" }
    
        # - Connect-Azure - as we are just testing the functionality of the Build-DockerImage function
        #                   connecting to Azure is not required and thus is mocked
        Mock -Command Connect-Azure -MockWith { return }
    
        $LASTEXITCODE = 0
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

    Context "Check mandatory parameters" {

        BeforeAll {

            # Mock Write-Error to check that it has been called
            Mock -CommandName Write-Error -MockWith {} -Verifiable
            Mock -CommandName Write-Information -MockWith {} -Verifiable
        }

        It "must error if no name is given for the image" {

            Build-DockerImage

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will set a default tag if one is not set" {

            Build-DockerImage -Name unittests

            Should -Invoke -CommandName Write-Information -Times 1
        }
        
        It "must error if trying to push and no registry has been specified" {

            Build-DockerImage -Name unittests -Push

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Build without push" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()            
        }

        It "will build an image using parameter values from the command line" {

            # Call the function under test
            Build-DockerImage -name pester-tests -tag "unittests"

            # Check that the command that will be run is correct
            # This is done by checking the command list
            $Session.commands.list[0] | Should -BeLike "*docker* build . -t pester-tests:unittests"
        }

        It "will tag the image accordingly if a registry is specified" {

            # Call the function under test
            Build-DockerImage -name pester-tests -tag "unittests" -Registry "pesterreg"

            $Session.commands.list[0] | Should -BeLike "*docker* build . -t pester-tests:unittests -t pesterreg/pester-tests:unittests -t pesterreg/pester-tests:latest"
        }
    }

    Context "Build image and push" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()            
        }
        
        It "will build and push the image to the specified registry" {

            # Call the function under test
            Build-DockerImage -name pester-tests -tag "unittests" -registry "docker.io" -push

            # Check the build command
            $Session.commands.list[0] | Should -BeLike "*docker* build . -t pester-tests:unittests -t docker.io/pester-tests:unittests -t docker.io/pester-tests:latest"

            # Check that docker logs into the registry
            $Session.commands.list[1] | Should -BeLike "*docker* login docker.io -u pester -p pester123"

            # Ensure that the image is pused to the registry
            $Session.commands.list[2] | Should -BeLike "*docker* push docker.io/pester-tests:unittests"
        }
    }
}