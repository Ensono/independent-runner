Describe "Update-BuildNumber" {

    BeforeAll {

        $envTfBuildBeforeTest = $env:TF_BUILD

        # Include the function under test
        . $PSScriptRoot/Update-BuildNumber.ps1

        # Include dependencies
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1

        # Mock commands
        # Write-Error - so that when a function cannot find what it requires, the
        # error is generates can be caught
        Mock -CommandName Write-Error -MockWith { }
    }

    Context "no build number is specified" {

        It "will error" {

            Update-BuildNumber

            Should -Invoke -CommandName Write-Error -Times -1
        }
    }

    Context "build number is set for Azure DevOps" {

        BeforeAll {
            # Set the environment variable to state running in Azure DevOps
            $env:TF_BUILD = $true
        }

        AfterAll {

            $env:TF_BUILD = $envTfBuildBeforeTest
        }

        It "will output update string" {

            Update-BuildNumber -BuildNumber "100.98.99" | Should -Be "##vso[build.updatebuildnumber]100.98.99"
        }
    }

    Context "Build number not updated for unupported platform" {
        BeforeAll {
            # Remove environment variable, set to state running not in Azure DevOps
            if (Test-Path -Path "Env:TF_BUILD") {
                Remove-Item -Path "Env:TF_BUILD"
            }
        }

        AfterAll {
            $env:TF_BUILD = $envTfBuildBeforeTest
        }

        It "will return basic string" {
            Update-BuildNumber -BuildNumber "100.98.98" | Should -Be "100.98.98"
        }
    }
}
