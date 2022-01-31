

Describe "Invoke-Kubectl" {

    BeforeAll {
        . $PSScriptRoot/Invoke-Kubectl.ps1
        . $PSScriptRoot/Invoke-Login.ps1
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
    
        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        $manifestFile = Join-Path -Path $testFolder -ChildPath "manifest.yml"
        New-Item -ItemType File -Path $manifestFile
    
        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }
    
        # Mock the Invoke-Login, this is so that no actually login is performed
        Mock -CommandName Invoke-Login -MockWith { return } -RemoveParameterValidation tenantId
    
        # Mock the Find-Command to return a valid path for the tool
        # This is so that the tool does not need to exist on the machine that is running the tests
        Mock -Command Find-Command -MockWith { return "kubectl" }
    }

    AfterAll {

        Remove-Variable -Name Session -Scope global
    }

    Context "Apply" {
        BeforeEach {

            Invoke-Kubectl -Apply -Arguments $manifestFile
        }

        It "will deploy the specified manifest" {
            $Session.commands.list[0] | Should -BeLike "*kubectl* apply -f *manifest.yml"
        }
    }

    Context "Custom" {

        It "will run the custom command" {
            Invoke-Kubectl -Custom -Arguments "deploy"

            $Session.commands.list[1] | Should -BeLike "*kubectl* deploy"
        }
    }

    Context "Rollout" {

        BeforeEach {
            Invoke-Kubectl -Rollout -Arguments "status -n pester deploy/pester --timeout 1200"
        }

        It "will check the status of the rollout" {
            $Session.commands.list[2] | Should -BeLike "*kubectl* rollout status -n pester deploy/pester --timeout 1200"
        }
    }

}