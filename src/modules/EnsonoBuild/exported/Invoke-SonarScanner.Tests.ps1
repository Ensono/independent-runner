Describe "Invoke-SonarScanner" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Invoke-SonarScanner.ps1

        # Import dependencies
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1

        # Mock commands
        # - Write-Error - mock this internal function to check that errors are being raised
        Mock -Command Write-Error -MockWith { return $MessageData } -Verifiable

        # - Find-Command - return the name of the command that is required
        Mock -Command Find-Command -MockWith { return $name }        
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

    Context "check parameters" {

        it "a SONAR_TOKEN must be specified" {

            Invoke-SonarScanner

            Should -Invoke -CommandName Write-Error 
        }

        it "only start or stop should be specified" {

            Invoke-SonarScanner -Token xxx -Start -Stop

            Should -Invoke -CommandName Write-Error 
        }

        it "will throw an error if not all parameters are set" {

            Invoke-SonarScanner -Token xxx -Start -ProjectName "pester"

            Should -Invoke -CommandName Write-Error 
        }
    }

    Context "will start a sonar session" {

        BeforeAll {

            # Set environment variables
            $env:PROJECT_NAME = "env_pester"
            $env:BUILD_BUILDNUMBER = "99.98.100"
            $env:SONAR_URL = "https://env.sonar.example"
            $env:SONAR_ORG = "AmidoStacks"
            $env:SONAR_TOKEN = "987654"
        }

        AfterAll {

            # Unset env vars
            Remove-Item env:\PROJECT_NAME
            Remove-Item env:\BUILD_BUILDNUMBER
            Remove-Item env:\SONAR_URL
            Remove-Item env:\SONAR_ORG
            Remove-Item env:\SONAR_TOKEN
        }

        It "using command line" {

            # Create a hashtable to splat into the command
            $splat = @{
                Start = $true
                ProjectName = "pester"
                BuildVersion = "100.98.99"
                URL = "https://sonarscanner.example"
                Organisation = "Amido"
                Token = "123456"
            }

            Invoke-SonarScanner @Splat

            # Build up the command that is expected
            $expected = "*dotnet-sonarscanner* begin /k:{0} /v:{1} /d:sonar.host.url={2} /o:{3} /d:sonar.login={4}" -f `
                $splat.ProjectName, `
                $splat.BuildVersion, `
                $splat.URL, `
                $splat.Organisation, `
                $splat.Token

            # Check the command that would be executed
            $Session.commands.list[0] | Should -BeLike $expected

        }

        It "using environment variables" {

            # Start the sonar session
            Invoke-SonarScanner -Start

            # Build up the command that is expected
            $expected = "*dotnet-sonarscanner* begin /k:{0} /v:{1} /d:sonar.host.url={2} /o:{3} /d:sonar.login={4}" -f `
                $env:PROJECT_NAME, `
                $env:BUILD_BUILDNUMBER, `
                $env:SONAR_URL, `
                $env:SONAR_ORG, `
                $env:SONAR_TOKEN

            # Check the command that would be executed
            $Session.commands.list[0] | Should -BeLike $expected
        }
    }

    Context "will stop a sonar session" {

        BeforeAll {

            # Set an env var for the SONAR_TOKEN
            $env:SONAR_TOKEN = "654321"
        }

        AfterAll {

            Remove-Item env:\SONAR_TOKEN
        }

        It "using command line" {

            Invoke-SonarScanner -Stop -Token 11111

            # Check the command that would be executed
            $Session.commands.list[0] | Should -BeLike "*dotnet-sonarscanner* end /d:sonar.login=11111"
        }

        It "environment vars" {

            Invoke-SonarScanner -Stop

            # Check the command that would be executed
            $Session.commands.list[0] | Should -BeLike "*dotnet-sonarscanner* end /d:sonar.login=654321"
        }
    }
}