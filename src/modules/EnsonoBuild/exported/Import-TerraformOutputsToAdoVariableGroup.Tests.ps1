Describe "Import-TerraformOutputsToAdoVariableGroup" {

    $ModulePath

    BeforeAll {

        $InformationPreference = 'Continue'

        # Import the function being tested
        . $PSScriptRoot/Import-TerraformOutputsToAdoVariableGroup.ps1

        # Mock the REST API calls
        Mock -Command Invoke-RestMethod -MockWith {
            return [PSCustomObject]@{
                id = "test-project-id"
                name = "test-project"
            }
        }

        Mock -Command Write-Host -MockWith {}
        Mock -Command Write-Error -MockWith {}

        # Create all test files upfront
        $testOutputs = @{
            resource_group_name = @{
                value = "test-rg"
                sensitive = $false
            }
            location = @{
                value = "eastus"
                sensitive = $false
            }
            secret_value = @{
                value = "my-secret"
                sensitive = $true
            }
        } | ConvertTo-Json -Depth 10
        Set-Content -Path "test-outputs.json" -Value $testOutputs

        $testComplexOutputs = @{
            servicebus_topics = @{
                value = @{
                    topic1 = "sb-topic-1"
                    topic2 = "sb-topic-2"
                }
                sensitive = $false
            }
            storage_accounts = @{
                value = @{
                    primary = "stgprimary"
                    secondary = "stgsecondary"
                }
                sensitive = $false
            }
        } | ConvertTo-Json -Depth 10
        Set-Content -Path "test-complex-outputs.json" -Value $testComplexOutputs

        $testDryrunOutputs = @{
            test_var = @{
                value = "test-value"
                sensitive = $false
            }
        } | ConvertTo-Json -Depth 10
        Set-Content -Path "test-dryrun-outputs.json" -Value $testDryrunOutputs

        $testCreateOutputs = @{
            new_var = @{
                value = "new-value"
                sensitive = $false
            }
        } | ConvertTo-Json -Depth 10
        Set-Content -Path "test-create-outputs.json" -Value $testCreateOutputs

        $testUpdateOutputs = @{
            updated_var = @{
                value = "updated-value"
                sensitive = $false
            }
        } | ConvertTo-Json -Depth 10
        Set-Content -Path "test-update-outputs.json" -Value $testUpdateOutputs

        $testOutputOnlyOutputs = @{
            output_only_var = @{
                value = "output-value"
                sensitive = $false
            }
        } | ConvertTo-Json -Depth 10
        Set-Content -Path "test-output-only.json" -Value $testOutputOnlyOutputs
    }

    AfterAll {
        # Clean up all test files
        Remove-Item -Path "test-outputs.json" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "test-complex-outputs.json" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "test-dryrun-outputs.json" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "test-create-outputs.json" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "test-update-outputs.json" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "test-output-only.json" -Force -ErrorAction SilentlyContinue
    }

    Context "Check mandatory parameters" {

        It "will error if Terraform outputs file does not exist" {
            { 
                Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "vars" -terraformOutputs "non-existent.json"
            } | Should -Throw "*Missing Terraform json output file*"
        }
    }

    Context "Process Terraform outputs - simple values" {

        It "will process simple Terraform output values" {
            Mock -CommandName Write-Host -MockWith {}
            Mock -CommandName Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-outputs.json" -dryRun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*Processing Terraform outputs*" } -Times 1
        }

        It "will create ADO pipeline output variables for simple values" {
            Mock -CommandName Write-Host -MockWith {}
            Mock -CommandName Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-outputs.json" -dryRun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*##vso``[task.setvariable*" } -Times 1 -Exactly:$false
        }

        It "will apply variable name prefix when specified" {
            Mock -Command Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -variableNamePrefix "TF_" -terraformOutputs "test-outputs.json" -dryRun

            Should -Invoke -CommandName Write-Host -Times 1
        }
    }

    Context "Process Terraform outputs - complex objects" {

        It "will flatten complex object outputs into individual variables" {
            Mock -Command Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-complex-outputs.json" -dryRun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*servicebus_topic_topic1*" } -Times 1
        }

        It "will create variables with singularized prefix from plural output names" {
            Mock -Command Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-complex-outputs.json" -dryRun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*storage_account_*" } -Times 1
        }
    }

    Context "Dry run functionality" {

        It "will display dry run warning when dryRun is enabled" {
            Mock -Command Invoke-RestMethod -MockWith {
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-dryrun-outputs.json" -dryRun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*DRY RUN MODE*" } -Times 1
        }

        It "will not call ADO API to create variable group during dry run" {
            Mock -Command Invoke-RestMethod -MockWith {
                param($method)
                if ($method -eq "POST") {
                    throw "Should not be called in dry run mode"
                }
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                    count = 0
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-dryrun-outputs.json" -dryRun

            Should -Invoke -CommandName Invoke-RestMethod -ParameterFilter { $method -eq "POST" } -Times 0
        }
    }

    Context "Variable group creation" {

        It "will create a new variable group when it does not exist" {
            Mock -Command Invoke-RestMethod -MockWith {
                param($method, $uri)
                if ($method -eq "POST") {
                    return [PSCustomObject]@{
                        id = "new-group-id"
                        name = "new-vars"
                    }
                }
                # GET calls return project or empty variable group list
                if ($uri -like "*variablegroups*") {
                    return [PSCustomObject]@{
                        count = 0
                        value = @()
                    }
                }
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "new-vars" -terraformOutputs "test-create-outputs.json"

            Should -Invoke -CommandName Invoke-RestMethod -ParameterFilter { $method -eq "POST" } -Times 1
        }

        It "will display creation message when creating new variable group" {
            Mock -Command Invoke-RestMethod -MockWith {
                param($method, $uri)
                if ($uri -like "*variablegroups*" -and $method -eq "GET") {
                    return [PSCustomObject]@{
                        count = 0
                        value = @()
                    }
                }
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "new-vars" -terraformOutputs "test-create-outputs.json"

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*ACTION: Create*" } -Times 1
        }
    }

    Context "Variable group update" {

        It "will update an existing variable group when it exists" {
            Mock -Command Invoke-RestMethod -MockWith {
                param($method, $uri)
                if ($method -eq "PUT") {
                    return [PSCustomObject]@{
                        id = "existing-group-id"
                        name = "existing-vars"
                    }
                }
                # GET for variable groups returns existing group
                if ($uri -like "*variablegroups*") {
                    return [PSCustomObject]@{
                        count = 1
                        value = @(
                            [PSCustomObject]@{
                                id = "existing-group-id"
                                name = "existing-vars"
                                variables = [PSCustomObject]@{
                                    existing_var = [PSCustomObject]@{
                                        value = "old-value"
                                        isSecret = $false
                                    }
                                }
                            }
                        )
                    }
                }
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "existing-vars" -terraformOutputs "test-update-outputs.json"

            Should -Invoke -CommandName Invoke-RestMethod -ParameterFilter { $method -eq "PUT" } -Times 1
        }

        It "will display update message when updating existing variable group" {
            Mock -Command Invoke-RestMethod -MockWith {
                param($method, $uri)
                if ($uri -like "*variablegroups*" -and $method -eq "GET") {
                    return [PSCustomObject]@{
                        count = 1
                        value = @(
                            [PSCustomObject]@{
                                id = "existing-group-id"
                                name = "existing-vars"
                                variables = [PSCustomObject]@{}
                            }
                        )
                    }
                }
                return [PSCustomObject]@{
                    id = "project-id"
                    name = "test-project"
                }
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "existing-vars" -terraformOutputs "test-update-outputs.json"

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*ACTION: Update*" } -Times 1
        }
    }

    Context "createOutputVariablesOnly mode" {

        It "will skip variable group creation when createOutputVariablesOnly is set" {
            Mock -Command Invoke-RestMethod -MockWith {
                throw "Should not call ADO API when createOutputVariablesOnly is set"
            }

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-output-only.json" -createOutputVariablesOnly

            Should -Invoke -CommandName Invoke-RestMethod -Times 0
        }

        It "will still create pipeline output variables when createOutputVariablesOnly is set" {
            Mock -CommandName Write-Host -MockWith {}

            Import-TerraformOutputsToAdoVariableGroup -organisationName "org" -projectName "test" -accessToken "token" -variableGroupName "test-vars" -terraformOutputs "test-output-only.json" -createOutputVariablesOnly

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*##vso``[task.setvariable*" } -Times 1 -Exactly:$false
        }
    }
}
