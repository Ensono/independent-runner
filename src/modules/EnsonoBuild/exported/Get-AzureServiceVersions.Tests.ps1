
Describe "Get-AzureServiceVersions" {

    BeforeAll {
        # Include function under test
        . $PSScriptRoot/Get-AzureServiceVersions.ps1

        # Mock built in functions
        Mock -Command Write-Error -MockWith {}
        Mock -Command Connect-AzAccount -MockWith {}

        New-Module -Name AzurePowershell -ScriptBlock {
            function Get-AzAksVersion () {

                return @(
                    @{
                        OrchestratorVersion = "1.24.5"
                    },
                    @{
                        OrchestratorVersion = "1.25.5"
                    }
                )
            }
        }
        
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