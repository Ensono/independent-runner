
Describe "Confirm-Environment" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Confirm-Environment.ps1

        # Import dependent functions
        . $PSScriptRoot/../command/Stop-Task.ps1
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1    

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Create file to be used for testing
        $stageVarFile = [IO.Path]::Combine($testFolder, "stagevars.yml")
        Set-Content -Path $stageVarFile -Value @"
default:
    variables:
    credentials:
        azure:
            - name: ARM_CLIENT_ID

stages:
    - name: pester
      variables:
        - name: PESTER_TEST_VAR
        - name: TF_region
          cloud: [aws]
"@

        # Mocks
        # Write-Error - mock to the function that writes out errors
        Mock -Command Write-Host -MockWith {}
        Mock -Command Write-Warning -MockWith {}

    }

    Context "Check parameters" {

        It "will error if no path is provided" {

            { Confirm-Environment } | Should -Throw "Task failed due to errors detailed above"

            Should -Invoke -CommandName Write-Host -Times 1
        }
    }

    Context "Enviroment" {

        It "will error and terminate because PESTER_TEST_VAR is not set" {

            { Confirm-Environment -Path $stageVarFile -Stage "pester" } | Should -Throw "Task failed due to errors detailed above"

        }

        # Check that the function will warn if no stage has been specfied
        # As there are no default variables in the above config file there will be
        # no error or exception
        It "will warn if no stage has been specified" {

            Confirm-Environment -Path $stageVarFile

            Should -Invoke -CommandName Write-Warning -Times 1 
        }

        it "will ignot cloud specific vars if no cloud has been specified" {
            $results = Confirm-Environment -Path $stageVarFile -Passthru -stage pester

            $results.count | Should -Be 1
        }

        # Ensure that when a cloud has been specified the corect number of missing variables is set properly
        # This tests that cloud specified variables can be added to the configuration file and referenced properly
        it "will check cloud specific variables" {

            $results = Confirm-Environment -Path $stageVarFile -Cloud aws -Passthru -stage pester

            $results.count | Should -Be 2
        }
    }
}
