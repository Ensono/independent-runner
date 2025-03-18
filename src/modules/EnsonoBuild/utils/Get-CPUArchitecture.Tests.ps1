Describe "Get-CPUArchitecture" {

    BeforeAll {

        # Include the function under test
        . $PSScriptRoot/Get-CPUArchitecture.ps1

        # Include dependent functions
        . $PSScriptRoot/../exported/Invoke-External.ps1
    }

    Context "Windows platform" {

        BeforeAll {

            Mock -Command Invoke-External -MockWith { return "x86_64" }
        }

        It "should return amd64" {

            if (!(Test-Path -Path Env:\PROCESSOR_ARCHITECTURE)) {
                $env:PROCESSOR_ARCHITECTURE = "amd64"
            }

            $result = Get-CPUArchitecture -os windows

            $result | Should -be "amd64"
        }
    }

    Context "Linux platform - x86_64" {

        BeforeAll {

            Mock -Command Invoke-External -MockWith { return "x86_64" }
        }

        It "should return amd64" {

            $result = Get-CPUArchitecture -os linux

            $result | Should -be "amd64"
        }
    }

    Context "Linux platform - arm64" {

        BeforeAll {

            Mock -Command Invoke-External -MockWith { return "arm64" }
        }

        It "should return arm64" {

            $result = Get-CPUArchitecture -os linux

            $result | Should -be "arm64"
        }
    }
}
