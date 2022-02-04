
Describe "Confirm-SemVer" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Confirm-SemVer.ps1
    
        # Import dependencies for the function
        # N/A
    
        # Mock commands to check that they have been called
        # N/A
    }

    It "will attempt to test Confirm-SemVer with valid semver" {

        # call the command under test
        $result = Confirm-SemVer "1.2.3-unstable"

        $result | Should -BeTrue
    }

    It "will attempt to test Confirm-SemVer with invalid semver" {

        # call the command under test
        $result = Confirm-SemVer "No"

        $result | Should -BeFalse
    }

    It "will attempt to test Confirm-SemVer with no input" {

        # call the command under test
        $result = Confirm-SemVer ""

        $result | Should -BeFalse
    }


}
