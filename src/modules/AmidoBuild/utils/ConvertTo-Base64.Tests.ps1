
Describe "ConvertTo-Base64" {

    BeforeAll {

        # Incldue the function under test
        . $PSScriptRoot/ConvertTo-Base64.ps1
    }

    It "returns <expected> for '<value>'" -ForEach @(
        @{ value = ""; expected = ""}
        @{ value = "hello"; expected = "aGVsbG8="}
    ) {
        $result = ConvertTo-Base64 -value $value

        $result | Should -Be $expected
    }
}