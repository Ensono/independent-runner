Describe "Find-Command" {

    BeforeAll {

        # Include the function under test
        . $PSScriptRoot/Find-Command.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Mock
        Mock -Command Write-Error -MockWith {}
    }

    Context "Command cannot be found" {

        It "will error" {

            Find-Command -Name "mycommand"

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Command is in a folder in the path" {

        BeforeAll {

            # Mock the Get-Command so that the mycommand can be found
            Mock -Command Get-Command -MockWith { return (Join-Path -Path $testFolder -ChildPath $name[0]) }

        }

        It "will return the full path to the command" {

            $cmd = Find-Command -Name "mycommand"

            $cmd | Should -BeLike "*mycommand*"
        }
    }
}