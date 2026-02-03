# TODO: Review this soon, as it seems to be relying on other behaviour...
Describe "New-EnvConfig" {

    BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1

        # Import function under test
        . $PSScriptRoot/New-EnvConfig.ps1

        # Import dependent functions
        . $PSScriptRoot/../exported/Stop-Task.ps1
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1
        . $PSScriptRoot/../utils/Get-EnvConfig.ps1

        # Import dependent classes
        . $PSScriptRoot/../classes/StopTaskException.ps1

        # Create the testFolder
        $testFolder = New-TestDir

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
        Mock -Command Write-Warning -MockWith {}
        Mock -Command Write-Error -MockWith {}
        Mock -Command ConvertFrom-Yaml -MockWith { param($Yaml) return @{} }
        
        # Mock Get-Module to pretend Powershell-Yaml is installed
        Mock -Command Get-Module -MockWith {
            return @{
                Name = "Powershell-Yaml"
                Version = "0.4.2"
            }
        } -ParameterFilter { $Name -eq "Powershell-Yaml" }
        
        # Mock Import-Module for Powershell-Yaml
        Mock -Command Import-Module -MockWith {} -ParameterFilter { $Name -eq "Powershell-Yaml" }
        
        # Mock ConvertFrom-Yaml to parse the YAML content
        Mock -Command ConvertFrom-Yaml -MockWith {
            param($Yaml)
            # Simple YAML parser for test data
            $result = @{
                default = @{
                    variables = @()
                    credentials = @{
                        azure = @(
                            @{ name = "ARM_CLIENT_ID" }
                        )
                    }
                }
                stages = @(
                    @{
                        Name = "pester"
                        variables = @(
                            @{
                                name = "PESTER_TEST_VAR"
                                description = "Test variable for Pester unit tests"
                            },
                            @{
                                name = "TF_region"
                                cloud = @("aws")
                            }
                        )
                    }
                )
            }
            return $result
        }

    }

    Context "Check parameters" {

        It "will error if path and scriptPath have not been specified" {
            New-EnvConfig

            Should -InvokeVerifiable
            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will error if the path to the config file is not specified" {

            { New-EnvConfig -Path $testFolder/pester.yaml -ScriptPath $testFolder }
            | Should -Throw "Specified file does not exist: $testFolder/pester.yaml`nTask failed due to errors detailed above"

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Create script" {

        It "will create a PowerShell script with vars - Azure" {
            # Remove SHELL env var to ensure PowerShell script is created
            if (Test-Path env:\SHELL) {
                Remove-Item -Path env:\SHELL
            }

            New-EnvConfig -Path $stageVarFile -ScriptPath $testFolder -Cloud Azure -Stage pester

            $scriptPath = [IO.Path]::Combine($testFolder, "envvar-azure-pester.ps1")

            # Check that the script has been created
            Test-Path -Path $scriptPath | Should -BeTrue

            # Ensure the script has the correct format
            $script = Get-Content -Path $scriptPath
            $script | Select-String -Pattern '\$env\:[A-Z_]*=\".*\"$' | Should -BeTrue
            $script | Select-String -Pattern "^#\s+Test variable for pester unit tests"
        }

        It "will create a bash compatible script - Azure" {

            $env:SHELL = "bash"

            New-EnvConfig -Path $stageVarFile -ScriptPath $testFolder -Cloud Azure -Stage pester

            $scriptPath = [IO.Path]::Combine($testFolder, "envvar-azure-pester.sh")

            # Check that the script has been created
            Test-Path -Path $scriptPath | Should -BeTrue

            # Ensure the script has the correct format
            $script = Get-Content -Path $scriptPath
            $script | Select-String -Pattern 'export [A-Z_]*=\".*\"$' | Should -BeTrue
            $script | Select-String -Pattern "^#\s+Test variable for pester unit tests"

            Remove-Item -Path env:\SHELL
        }

        It "will create a PowerShell script with vars - AWS" {
            # Remove SHELL env var to ensure PowerShell script is created
            if (Test-Path env:\SHELL) {
                Remove-Item -Path env:\SHELL
            }

            New-EnvConfig -Path $stageVarFile -ScriptPath $testFolder -Cloud AWS -Stage pester

            $scriptPath = [IO.Path]::Combine($testFolder, "envvar-aws-pester.ps1")

            # Check that the script has been created
            Test-Path -Path $scriptPath | Should -BeTrue

            # Ensure the script has the correct format
            $script = Get-Content -Path $scriptPath
            $script | Select-String -Pattern '\$env\:[A-Z_]*=\".*\"$' | Should -BeTrue
        }

        It "will create a bash compatible script - AWS" {

            $env:SHELL = "bash"

            New-EnvConfig -Path $stageVarFile -ScriptPath $testFolder -Cloud AWS -Stage pester

            $scriptPath = [IO.Path]::Combine($testFolder, "envvar-azure-pester.sh")

            # Check that the script has been created
            Test-Path -Path $scriptPath | Should -BeTrue

            # Ensure the script has the correct format
            $script = Get-Content -Path $scriptPath
            $script | Select-String -Pattern 'export [A-Z_]*=\".*\"$' | Should -BeTrue

            Remove-Item -Path env:\SHELL
        }
    }
}


