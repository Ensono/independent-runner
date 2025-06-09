
Describe "Get-TFVars" {

    BeforeAll {
        # Import the function being tested
        . $PSScriptRoot/Get-TFVars.ps1

        # Set variables to be used in the tests
        $name = "ernesto"
        $project = "stacks"
        $random = "randomstring"
    }

    It "will create key/value pair string using default prefix" {

        $env:TF_VAR_name = $name
        $env:TF_VAR_project = $project
        $env:random = $random

        $keyValuePairs = Get-TFVars | Sort-Object

        # Ensure the result is not empty
        $keyValuePairs | Should -Not -BeNullOrEmpty

        # Check that there are two key/value pairs in the output
        $keyValuePairs.Count | Should -Be 2

        # Ensure that the key/value pairs are as expected
        $keyValuePairs[0] | Should -Match ('^name\s+=\s+"{0}"' -f $name)
        $keyValuePairs[1] | Should -Match ('^project\s+=\s+"{0}"' -f $project)

    }

    It "will create key/value pair string using custom prefix" {

        $env:OWN_VAR_name = $name
        $env:OWN_VAR_project = $project
        $env:random = $random

        $keyValuePairs = Get-TFVars -Prefix "OWN_VAR_*" | Sort-Object

        # Ensure the result is not empty
        $keyValuePairs | Should -Not -BeNullOrEmpty

        # Check that there are two key/value pairs in the output
        $keyValuePairs.Count | Should -Be 2

        # Ensure that the key/value pairs are as expected
        $keyValuePairs[0] | Should -Match ('^name\s+=\s+"{0}"' -f $name)
        $keyValuePairs[1] | Should -Match ('^project\s+=\s+"{0}"' -f $project)

    }
}
