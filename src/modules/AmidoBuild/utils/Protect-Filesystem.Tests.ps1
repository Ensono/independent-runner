Describe "Protect-Filesystem" {

    BeforeAll {

        # Include functions under test
        . $PSScriptRoot/Protect-Filesystem.ps1

        # Include dependent functions
        . $PSScriptRoot/Confirm-Parameters.ps1

        # Create test folder to work with
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Mock functions
        Mock -CommandName Write-Error -MockWith {}
        Mock -CommandName Write-Warning -MockWith {} -ParameterFilter { $Message.ToLower().Contains("specified output path does not exist, creating")}
        Mock -CommandName Write-Error -MockWith {} -ParameterFilter { $Message.ToLower().Contains("specified output path does not exist within the current directory")}
    }

    AfterEach {
        Remove-Item -Path "${testFolder}/*" -Recurse -Force
    }

    It "will throw an error if path is not specified" {

        $result = Protect-Filesystem

        $result | Should -Be $false

        Should -Invoke -CommandName Write-Error -Times 1
    }

    It "will throw an error if the path does not exist and is outside of the current dir" {

        $result = Protect-Filesystem -Path "../../" -BasePath $testFolder

        $result | Should -Be $false

        Should -Invoke -CommandName Write-Error -Times 1
    }

    It "will create the path with a warning" {

        $result = Protect-Filesystem -Path "outputs" -BasePath $testFolder

        Test-Path -Path $result | Should -Be $true
        Should -Invoke -CommandName Write-Warning -Times 1
    }
}
