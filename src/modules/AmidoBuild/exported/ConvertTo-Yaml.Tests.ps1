
Describe "ConvertTo-Yaml" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/ConvertTo-Yaml.ps1

        # Mocks
        Mock -Command Write-Error -MockWith { }
    }

    Context "Null input" {

        it "will return a null output" {
            $result = ConvertTo-Yaml ""

            $result | Should -BeNullOrEmpty
        }
    }

    Context "Hashtable input" {

        it "will convert a simple hashtable to Yaml" {

            $data = @{"name" = "pester"}

            ConvertTo-Yaml $data | Should -BeLike "*name: 'pester'"
        }

        it "will convert bool values" {

            $data = @{"on" = $true; "off" = $false}
            $result = ConvertTo-Yaml $data

            $result | Should -Match "(?m)---\s+on:\s+true\s+\r?\n\s+off:\s+false"
        }

        it "will output a Yaml structure from a complex hashtable" {

            $json = '{"k8s_version": "1.24.6", "k8s_versions": ["1.24.6", "1.25.7"]}'
            $data = ConvertFrom-Json -InputObject $json
            $result = ConvertTo-Yaml $data

            $result | Should -Match -RegularExpression "(?m)---\s+k8s_version:\s+'1\.24\.6'\s+k8s_versions:\s+-\s+'1\.24\.6'\s+-\s+'1\.25\.7'"
        }

        it "will convert a Json input to Yaml" {

            $json = '{"name": "pester"}'
            $data = ConvertFrom-Json -InputObject $json

            ConvertTo-Yaml $data | Should -BeLike "*name: 'pester'"
        }
    }
}