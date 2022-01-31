
Describe "Convert-HashToString" {

    BeforeAll {

        # Include the function under test
        . $PSSCriptRoot/Convert-HashToString.ps1

        # Include dependent functions
        . $PSScriptRoot/Confirm-Parameters.ps1
        . $PSScriptRoot/Convert-ArrayToString.ps1

        # Mock functions
        Mock -CommandName Write-Error -MockWith { } -ParameterFilter {  $Message.ToLower().Contains("required parameters are missing") }
    }

    It "will error if a hash table is not supplied" {

        Convert-HashToString

        Should -Invoke -CommandName Write-Error -Times 1
    }

    It "will return a string for a 1 dimension array on the command line" {

        $hash = @{"name" = "pester"}

        $result = Convert-HashToString -hash $hash

        $result | Should -Be '@{name = "pester"}'
    }

    It "will return a valid string using the pipeline" {

        $hash = @{"name" = "pester"}

        $result = $hash | Convert-HashToString

        $result | Should -Be '@{name = "pester"}'
    }

    It "will return a valid string for a nested hashtable" {

        $hash = @{"name" = @{first = "pester"; last = "tests"}}

        $result = Convert-HashToString -hash $hash

        # create an array of regular expressions that will be used to test the output
        # this is done because the order of the items in resultant string is not guaranteed
        # and ultimately does not matter
        $patterns = @(
            'name\s*=\s*@\{'
            'last\s*=\s*"'
            'first\s*=\s*"'
        )

        # iterate around the patterns
        foreach ($pattern in $patterns) {
            $result -match $pattern | Should -Be $true
        }

        # $result | Should -Be '@{name = @{last = "tests"; first = "pester"}}'
    }

    It "will return a valid string for a hashtable containing an array" {

        $hash = @{"name" = @{first = "pester"; last = "tests"}; "sports" = @("cricket", "tennis", "football")}

        $result = Convert-HashToString -hash $hash

        # create an array of regular expression patterns to match against
        $patterns = @(
            'name\s*=\s*@\{'
            'last\s*=\s*"'
            'first\s*=\s*"'
            'sports\s*=\s*@\("'            
        )

        # iterate around the patterns
        foreach ($pattern in $patterns) {
            $result -match $pattern | Should -Be $true
        }

        # $result | Should -Be '@{name = @{last = "tests"; first = "pester"}; sports = @("cricket", "tennis", "football")}'
    }
}
