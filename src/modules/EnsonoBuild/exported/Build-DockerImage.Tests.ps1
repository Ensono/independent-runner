Describe "Build-DockerImage" {

    BeforeAll {
        # Null any env vars which can be used to alter behaviour of the command
        #$env:REGISTRY_RESOURCE_GROUP = $null
        #$env:DOCKER_IMAGE_NAME = $null
        #$env:DOCKER_IMAGE_TAG = $null
        #$env:DOCKER_CONTAINER_REGISTRY_NAME = $null
        #$env:ECR_REGION = $null
        #$env:REGISTRY_RESOURCE_GROUP = $null

        # Import the function being tested
        . $PSScriptRoot/Build-DockerImage.ps1

        # Import dependent scripts
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Stop-Task.ps1
        . $PSScriptRoot/../utils/Confirm-TrunkBranch.ps1

        # Make stubbed module available
        # This stubs out Az.ContainerRegistry and Powershell-Yaml so that the full modules are not required
        $ModulePath = $env:PSModulePath
        $env:PSModulePath = "$PSScriptRoot/../../../../test/stubs/modules$([IO.Path]::PathSeparator)$env:PSModulePath"

        # Mock functions that are called
        # - Find-Command - return "docker" as the command withouth looking at the filesystem as Docker may
        #                  not exist in the testing environment
        Mock -Command Find-Command -MockWith { return "docker" }

        # Mock commands for the tests
        Mock -Command Confirm-TrunkBranch -MockWith { $true }
    }

    AfterAll {
        $env:PSModulePath = $ModulePath
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
            Mock -CommandName Write-Error -MockWith {} -Verifiable
            Mock -CommandName Write-Information -MockWith {} -Verifiable
        }

        It "must error if no name is given for the image" {
            $ShouldParams = @{
                Throw = $true
                ExpectedMessage = "Parameter set cannot be resolved using the specified named parameters. One or more parameters issued cannot be used together or an insufficient number of parameters were provided."
                ExceptionType = [System.Management.Automation.ParameterBindingException]
                # Command to run
                ActualValue = { Build-DockerImage }
            }

            Should @ShouldParams
        }

        It "will set a default tag if one is not set" {
            Build-DockerImage -Name unittests

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "must error if trying to push and no registry has been specified" {
            Build-DockerImage  -Name unittests -Push

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "must error if trying to push to a generic registry and do not specify DOCKER_USERNAME or DOCKER_PASSWORD env vars" {
            Build-DockerImage  -Name unittests -Push -Provider "Generic"

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    <#
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
            $Session.commands.list[0] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests --platform linux/arm64,linux/amd64"
        }
    }
    #>
}


<#
Describe "Build-DockerImage" {

    $ModulePath

    BeforeAll {

        $InformationPreference = 'Continue'

        # Null any env vars which can be used to alter behaviour of the command
        $env:REGISTRY_RESOURCE_GROUP = $null
        $env:DOCKER_IMAGE_NAME = $null
        $env:DOCKER_IMAGE_TAG = $null
        $env:DOCKER_CONTAINER_REGISTRY_NAME = $null
        $env:ECR_REGION = $null
        $env:REGISTRY_RESOURCE_GROUP = $null

        # Make stubbed module available
        $ModulePath = $env:PSModulePath
        $env:PSModulePath = "$PSScriptRoot/../../../../test/stubs/modules$([IO.Path]::PathSeparator)$env:PSModulePath"

        # Import the function being tested
        . $PSScriptRoot/Build-DockerImage.ps1

        # Import dependencies that the function under test requires
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../cloud/Connect-Azure.ps1
        . $PSScriptRoot/../utils/Confirm-TrunkBranch.ps1

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

        Mock -Command Confirm-TrunkBranch -MockWith { $true }
    }

    AfterAll {
        $env:PSModulePath = $ModulePath
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
            Mock -CommandName Write-Error -MockWith {} -Verifiable
            Mock -CommandName Write-Information -MockWith {} -Verifiable
        }

        It "must error if no name is given for the image" {
            $ShouldParams = @{
                Throw = $true
                ExpectedMessage = "Parameter set cannot be resolved using the specified named parameters. One or more parameters issued cannot be used together or an insufficient number of parameters were provided."
                ExceptionType = [System.Management.Automation.ParameterBindingException]
                # Command to run
                ActualValue = { Build-DockerImage }
            }

            Should @ShouldParams
        }

        It "will set a default tag if one is not set" {
            Build-DockerImage -Name unittests

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "must error if trying to push and no registry has been specified" {
            Build-DockerImage  -Name unittests -Push

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "must error if trying to push to a generic registry and do not specify DOCKER_USERNAME or DOCKER_PASSWORD env vars" {
            Build-DockerImage  -Name unittests -Push -Provider "Generic"

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
            $Session.commands.list[0] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests --platform linux/arm64,linux/amd64"
        }

        It "will build the image and set a different platform to build for" {

            # Call the function under test
            Build-DockerImage -name pester-tests -tag "unittests" -platforms "linux/arm/v7"

            # Check that the command that will be run is correct
            # This is done by checking the command list
            $Session.commands.list[0] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests --platform linux/arm/v7"
        }

        It "will tag the image accordingly if a registry is specified" {

            # Call the function under test
            Build-DockerImage -name pester-tests -tag "unittests" -Registry "pesterreg"

            $Session.commands.list[0] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests -t pesterreg/pester-tests:unittests --platform linux/arm64,linux/amd64"
        }

        It "will correctly change the case of the input to create a valid image" {

            # Call the function under test
            Build-DockerImage -name Pester-tests -tag "Unittests" -Registry "pesterreg"

            $Session.commands.list[0] | Should -BeLikeExactly "*docker* buildx build . -t pester-tests:unittests -t pesterreg/pester-tests:unittests --platform linux/arm64,linux/amd64"

        }

        it "will tag latest, even if not running on trunk branch, and the force flag is used" {

            Mock -Command Confirm-TrunkBranch -MockWith { $false }

            # Call the function under test
            Build-DockerImage -name Pester-tests -tag "Unittests" -Registry "pesterreg" -latest -force

            $Session.commands.list[0] | Should -BeLikeExactly "*docker* buildx build . -t pester-tests:unittests -t pesterreg/pester-tests:unittests -t pesterreg/pester-tests:latest --platform linux/arm64,linux/amd64"
        }

        It "will remove quotes surrounding build args when passing to Docker" {

            # Call the function to test
            Build-DockerImage -name Pester-tests -tag "Unittests" -Registry "pesterreg" -BuildArgs "`"--build-arg functionName=PesterFunction .`""

            $Session.commands.list[0] | Should -BeLikeExactly "*docker* buildx build --build-arg functionName=PesterFunction . -t pester-tests:unittests -t pesterreg/pester-tests:unittests --platform linux/arm64,linux/amd64"
        }

    }

    Context "Build without push and set latest" {

        it "will tag with latest when on trunk branch and latest has been set" {

            # Call the function under test
            Build-DockerImage -name Pester-tests -tag "Unittests" -Registry "pesterreg" -latest

            $Session.commands.list[0] | Should -BeLikeExactly "*docker* buildx build . -t pester-tests:unittests -t pesterreg/pester-tests:unittests -t pesterreg/pester-tests:latest --platform linux/arm64,linux/amd64"
        }

        it "will not set latest if not on a trunk branch" {

            Mock -Command Confirm-TrunkBranch -MockWith { $false }

             # Call the function under test
             Build-DockerImage -name Pester-tests -tag "Unittests" -Registry "pesterreg" -latest

             $Session.commands.list[0] | Should -BeLikeExactly "*docker* buildx build . -t pester-tests:unittests -t pesterreg/pester-tests:unittests --platform linux/arm64,linux/amd64"
        }
    }

    Context "Build image and push to generic registry" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
            # Setup example Docker creds
            $env:DOCKER_USERNAME = "pester"
            $env:DOCKER_PASSWORD = "pester123"
        }

        It "will build and push the image to the specified generic registry" {

            # Call the function under test
            Build-DockerImage -provider "generic" -name pester-tests -tag "unittests" -registry "docker.io" -push

            # There should be two commands
            $Session.commands.list.length | Should -Be 2

            # Check that docker logs into the registry
            $Session.commands.list[0] | Should -BeLike "*docker* login docker.io -u pester -p pester123"

            # Check the build command
            $Session.commands.list[1] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests -t docker.io/pester-tests:unittests --platform linux/arm64,linux/amd64 --push"

        }

        It "will build the image but not push if the NO_ENV variable has been set" {

            # Check to see if the NO_PUSH env var already exists
            $no_push_exists = $false
            if (Test-Path -Path env:\NO_PUSH) {
                $no_push_exists = $env:NO_PUSH
            }

            # Set the environment variable to prevent the push
            $env:NO_PUSH = "do not push"

            # Call the function under test
            Build-DockerImage -provider "generic" -name pester-tests -tag "unittests" -registry "docker.io" -push

            # There should only be one command
            $Session.commands.list.length | Should -Be 1

            # Check the build command
            $Session.commands.list[0] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests -t docker.io/pester-tests:unittests --platform linux/arm64,linux/amd64"

            # Remove the environment variable
            if ($no_push_exists) {
                $env:NO_PUSH = $no_push_exists
            } else {
                remove-item -path env:\NO_PUSH
            }


        }

        AfterEach {
            # TODO: This should capture and re-set after
            $env:DOCKER_USERNAME = $null
            $env:DOCKER_PASSWORD = $null
        }
    }

    Context "Build image and push including latest to the specified generic registry" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
            # Setup example Docker creds
            $env:DOCKER_USERNAME = "pester"
            $env:DOCKER_PASSWORD = "pester123"
        }

        It "will build and push the image to the specified generic registry with a latest tag" {

            # Call the function under test
            Build-DockerImage -provider "generic" -name pester-tests -tag "unittests" -registry "docker.io" -push -latest

            # There should be two commands
            $Session.commands.list.length | Should -Be 2

            # Check that docker logs into the registry
            $Session.commands.list[0] | Should -BeLike "*docker* login docker.io -u pester -p pester123"

            # Check the build command
            $Session.commands.list[1] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests -t docker.io/pester-tests:unittests -t docker.io/pester-tests:latest --platform linux/arm64,linux/amd64 --push"
        }

        AfterEach {
            $env:DOCKER_USERNAME = $null
            $env:DOCKER_PASSWORD = $null
        }
    }

    Context "Build image and push to azure registry" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will build and push the image to the specified azure registry" {

            # Call the function under test
            Build-DockerImage -provider "azure" -group "test" -name pester-tests -tag "unittests" -registry "docker.io" -push

            # There should be two commands
            $Session.commands.list.length | Should -Be 2

            # Check that docker logs into the registry
            $Session.commands.list[0] | Should -BeLike "*docker* login docker.io -u pester -p pester123"

            # Check the build command
            $Session.commands.list[1] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests -t docker.io/pester-tests:unittests --platform linux/arm64,linux/amd64 --push"

        }
    }

    Context "Build image and push including latest to the specified azure registry" {
        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will build and push the image to the specified azure registry with a latest tag" {

            # Call the function under test
            Build-DockerImage -provider "azure"  -group "test"  -name pester-tests -tag "unittests" -registry "docker.io" -push -latest

            # There should be two commands
            $Session.commands.list.length | Should -Be 2

            # Check that docker logs into the registry
            $Session.commands.list[0] | Should -BeLike "*docker* login docker.io -u pester -p pester123"

            # Check the build command
            $Session.commands.list[1] | Should -BeLike "*docker* buildx build . -t pester-tests:unittests -t docker.io/pester-tests:unittests -t docker.io/pester-tests:latest --platform linux/arm64,linux/amd64 --push"
        }
    }
}
#>