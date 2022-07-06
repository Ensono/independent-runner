Describe "Get-EnvConfig" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Get-EnvConfig.ps1

        # Import dependent functions
        . $PSScriptRoot/../command/Stop-Task.ps1
        . $PSScriptRoot/Confirm-Parameters.ps1
        . $PSScriptRoot/Get-EnvConfig.ps1

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
          description: Test variable for Pester unit tests
        - name: TF_region
          cloud: [aws]
"@

        # Mocks
        # Write-Error - mock to the function that writes out errors
        Mock -Command Write-Host -MockWith {}
        Mock -Command Write-Warning -MockWith {}
        Mock -Command Write-Error -MockWith {}

    }

    It "will produce a warning if the stage is not specified" {

        $result = Get-EnvConfig -Path $stageVarFile -Cloud Azure

        $result.count | Should -Be 1
        Should -Invoke Write-Warning -Times 1
    }

    It "will return 2 items for Azure" {

        $result = Get-EnvConfig -Path $stageVarFile -Cloud Azure -Stage pester

        $result.count | Should -Be 2
    }

    It "will return 2 items for AWS" {
        $result = Get-EnvConfig -Path $stageVarFile -Cloud AWS -Stage pester

        $result.count | Should -Be 2
    }

}