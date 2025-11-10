
Describe "Get-AzureServiceVersions" {

    BeforeAll {
        # Create stub functions for Azure cmdlets before dot-sourcing
        function Connect-AzAccount { }
        function Get-AzAksVersion { }
        
        # Mock built-in functions
        Mock -Command Write-Error -MockWith {}
        Mock -Command ConvertTo-SecureString -MockWith {
            # Return a proper SecureString object
            $secure = New-Object System.Security.SecureString
            foreach ($char in "MockPassword".ToCharArray()) {
                $secure.AppendChar($char)
            }
            return $secure
        }
        Mock -Command New-Object -MockWith {
            param($TypeName, $ArgumentList)
            # Create a proper PSCredential mock
            if ($TypeName -eq "System.Management.Automation.PSCredential") {
                return [PSCredential]::new($ArgumentList[0], $ArgumentList[1])
            }
            # For other types, call the original
            return & (Get-Command New-Object -CommandType Cmdlet) -TypeName $TypeName -ArgumentList $ArgumentList
        } -ParameterFilter { $TypeName -eq "System.Management.Automation.PSCredential" }
        Mock -Command Connect-AzAccount -MockWith {
            return @{
                Context = @{
                    Account = @{
                        Id = "mock-sp"
                    }
                }
            }
        }
        Mock -Command Get-AzAksVersion -MockWith {
            return @(
                @{
                    OrchestratorVersion = "1.24.5"
                },
                @{
                    OrchestratorVersion = "1.25.5"
                }
            )
        }
        
        # Include function under test (after stubs and mocks are in place)
        . $PSScriptRoot/Get-AzureServiceVersions.ps1
    }

    Context "Parameters are sane" {

        it "will error if no services have been supplied" {
            Get-AzureServiceVersions 

            Should -Invoke -CommandName Write-Error -Times 1
        }

        it "will error if a location is not specified" {
            Get-AzureServiceVersions -services aks 

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Execute" {

        It "will return a list of versions" {

            $env:AZURE_CLIENT_ID = "fred"
            $env:AZURE_CLIENT_SECRET = "bloggs"
            $env:AZURE_TENANT_ID = "people"

            $result = Get-AzureServiceVersions -services aks -location westeurope

            $result["kubernetes_valid_versions"].Count | Should -Be 2
        }
    }
}
