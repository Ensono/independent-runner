
Describe "Confirm-CSL" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Confirm-CSL.ps1
    
        # Import dependencies for the function
        # N/A
    
        # Mock commands to check that they have been called
        # N/A
    }

    It "will attempt to test Confirm-CSL with valid comma separated string" {

        # call the command under test
        $result = Confirm-CSL "1,yes,no-maybe,true=false"

        $result | Should -BeTrue
    }

    It "will attempt to test Confirm-CSL with badly formatted comma separated string" {

        # call the command under test
        $result = Confirm-CSL "1,yes,no-maybe,true=false,"

        $result | Should -BeFalse
    }

    It "will attempt to test Confirm-CSL with invalid values in comma separated string" {

        # call the command under test
        $result = Confirm-CSL "1,yes,no-maybe,true*false"

        $result | Should -BeFalse
    }


}