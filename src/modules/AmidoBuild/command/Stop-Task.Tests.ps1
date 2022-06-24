

Describe "Stop-Task" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Stop-Task.ps1

        # Include dependent functions
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1        

        # Mocks
        # Write-Error - mock to the function that writes out errors
        Mock -Command Write-Host -MockWith { }
    }

    It "will write out an error and produce an exception" {

        { Stop-Task -Message "Pester Test" } | Should -Throw "Task failed due to errors detailed above"

        Should -Invoke -CommandName Write-Host -Times 1
    }

}
