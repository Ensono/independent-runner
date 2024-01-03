
Describe "Confirm-Parameters" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Confirm-Parameters.ps1

        # Mock commands
        # - Write-Error - mock this internal function to check that errors are being raised
        Mock -Command Write-Error -MockWith { return $MessageData } -Verifiable        
    }

    It "will error as specified variable has not been set" {

        $result = Confirm-Parameters -List @("pester")

        $result | Should -Be $false
        Should -Invoke -CommandName Write-Error -Times 1

    }

    It "will return true if all required values are set" {

        New-Variable -Name Pester -Value "testing"

        $result = Confirm-Parameters -List @("pester")

        $result | Should -Be $true
    }
}