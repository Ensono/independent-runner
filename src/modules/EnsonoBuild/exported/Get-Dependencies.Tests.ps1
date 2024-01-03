
Describe "Get-Dependencies" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Get-Dependencies.ps1
    
        # Import dependencies for the function
        . $PSScriptRoot/Invoke-GitClone.ps1
    
        # Mock commands to check that they have been called
        # Invoke-GitClone - the command that performs the clone of the target repo
        Mock -Command Invoke-GitClone -MockWith {}
    
        # Write-Error - check that errors are bein raised appropriately
        Mock -Command Write-Error -MockWith {}
    }

    It "will attempt to call Invoke-GitClone twice with Github" {

        # call the command under test
        Get-Dependencies -type "github" -list @("pester-repo-1", "pester-repo-2")

        Should -Invoke -CommandName Invoke-GitClone -Times 2
    }

    It "does not call Invoke-GitClone when the type is not recognised" {

        # call the command under test
        Get-Dependencies -type "gitlab" -list @("pester-repo-1", "pester-repo-2")

        Should -Invoke -CommandName Write-Error -Times 1
    }
}