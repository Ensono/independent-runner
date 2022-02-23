
Describe "Invoke-PesterTests" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Invoke-PesterTests.ps1

        # Include dependent functions
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1

        # Mocks
        Mock -Command Invoke-Pester -MockWith { return }
        Mock -Command Write-Error -MockWith {}
        }
    
    AfterAll {
        # N/A
    }

    Context "it will error" {
        
        It "if path parameter has not been set" {

            Invoke-PesterTests

            Should -Invoke -CommandName Write-Error -Times 1
        }
    
    Context "it will invoke Pester" {
        BeforeEach {
            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force
        }
        
            It "if path parameter has been set" {
    
                Invoke-PesterTests -path $testFolder
    
                Should -Invoke -CommandName Invoke-Pester -Times 1
            }
        }
    }
}
