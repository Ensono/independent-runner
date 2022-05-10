Describe "Connect-EKS" {

    BeforeAll {

        # Import funciton under test
        . $PSScriptRoot/Connect-EKS.ps1

        # Import dependencies
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1

        # Mocks
        # - Write-Error
        Mock -CommandName Write-Error -MockWith {}

        # - Invoke-External
        Mock -CommandName Invoke-External -MockWith { return }
    }

    Context "Use parameters" {

        It "will raise an error as not all the required params have been set" {

            Connect-EKS

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will connect to Azure" {

          Connect-EKS -name xxxx -region yyyy

            Should -Invoke -CommandName Invoke-External -Times 1
        }
    }

}
