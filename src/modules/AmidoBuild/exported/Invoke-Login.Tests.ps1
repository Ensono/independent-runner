
Describe "Invoke-Login" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Invoke-Login.ps1

        # Import dependencies
        . $PSScriptRoot/../cloud/Connect-Azure.ps1

        # Functions
        # Create function signatures that are used so that they can be mocked
        # This prevents the module from having to be present to run the commands
        function Import-AzAksCredential() {
            param (
                [string]
                $resourceGroupName,

                [string]
                $name
            )
        }
    
        # Mock commands
        # - Write-Error - mock this internal function to check that errors are being raised
        Mock -Command Write-Error -MockWith { return $MessageData } -Verifiable

        # - Connect-Azure - as we are just testing the functionality of the Invoke-Login function
        #                   connecting to Azure is not required and thus is mocked
        Mock -Command Connect-Azure -MockWith { return }

        # - Import-AzAksCredential
        Mock -Command Import-AzAksCredential -MockWith {}
    
        # Create session variable
        New-Variable -Name Session -Scope Global -Value @{
            dryrun = $false
        }
    }
    
    AfterAll {
        Remove-Variable -Name Session -Scope Global
    }

    Context "No cloud platform is specified" {

        it "will error" {
            Invoke-Login

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Azure" {

        it "will error without all required parameters" {

            Invoke-Login -Azure -TenantId xxxx -SubscriptionId xxxx

            Should -Invoke -CommandName Write-Error -Times 1
        }

        it "will login to Azure" {

            $secure = ConvertTo-SecureString -AsPlainText -String xxxx
            Invoke-Login -Azure -TenantId xxxx -SubscriptionId xxxx -username xxxx -password $secure

            Should -Invoke -CommandName Connect-Azure -Times 1
            Should -Invoke -CommandName Import-AzAksCredential -Times 0
        }

        it "will log into Azure and get AKS credentials" {

            $secure = ConvertTo-SecureString -AsPlainText -String xxxx
            Invoke-Login -Azure -TenantId xxxx -SubscriptionId xxxx -username xxxx -password $secure -aks

            Should -Invoke -CommandName Connect-Azure -Times 1
            Should -Invoke -CommandName Import-AzAksCredential -Times 1           
        }
    }

}