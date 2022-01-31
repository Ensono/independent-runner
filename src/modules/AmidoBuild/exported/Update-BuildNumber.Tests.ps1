Describe "Update-BuildNumber" {

    BeforeAll {

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

            # Set the environment varibale to state running in Azure DevOps
            $env:TF_BUILD = $true
        }

        AfterAll {

            Remove-Item env:\TF_BUILD
        }

        It "will output update string" {

            Update-BuildNumber -BuildNumber "100.98.99" | Should -Be "##vso[build.updatebuildnumber]100.98.99"
        }
    }

    Context "Build number not updated for unupported platform" {

        It "will return null" {

            Update-BuildNumber -BuildNumber "100.98.99" | Should -Be $null
        }
    }
}