
Describe "Confirm-IsWebAddress" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Confirm-IsWebAddress.ps1
    }


    It "returns <expected> for <url>" -ForEach @(
        @{ url = "http://github.com"; expected = $true }
        @{ url = "http:/github.com"; expected = $false }
        @{ url = "http://github.com/amido\stacks-cli"; expected = $true }
        @{ url = "github.com"; expected = $false }
    ) {

        $result = Confirm-IsWebAddress -address $url

        $result | Should -Be $expected
    }
}