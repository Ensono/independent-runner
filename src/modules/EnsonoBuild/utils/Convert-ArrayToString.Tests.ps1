Describe "Convert-ArrayToString" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Convert-ArrayToString.ps1

        # Include dependent functions
        . $PSScriptRoot/Convert-HashToString.ps1
        . $PSScriptRoot/Confirm-Parameters.ps1

       # Mock functions
       Mock -CommandName Write-Error -MockWith { } -ParameterFilter {  $Message.ToLower().Contains("required parameters are missing") }        
    }

    It "will error if an array is not supplied" {

        Convert-ArrayToString

        Should -Invoke -CommandName Write-Error -Times 1
    }

    It "will return a string for single dimension array" {

        $test = @("foo", "bar")

        $result = Convert-ArrayToString -arr $test

        $result | Should -Be '@("foo", "bar")'
    }

    It "will return a string for a nested array" {

        $test = @(@("ball", "bike"), @("volvo", "fiat"))

        $result = Convert-ArrayToString -arr $test

        $result | Should -Be '@(@("ball", "bike"), @("volvo", "fiat"))'            
    }

    It "will return a string for an array with nested hashtable" {

        $test = @(@{"name" = "fred"}, "friends")

        $result = Convert-ArrayToString -arr $test

        $result | Should -Be '@(@{name = "fred"}, "friends")'
    }

    It "will return a valid empty array string" {

        $test = @()

        $result = Convert-ArrayToString -arr $test

        $result | Should -Be '@()'
    }
}
