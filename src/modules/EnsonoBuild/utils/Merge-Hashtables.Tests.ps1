
Describe "Merge-Hashtables" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Merge-Hashtables.ps1

        . $PSScriptRoot/Copy-Object.ps1

    }

    It "will merge two different hashtables" {

        $primary = @{"foo" = "bar"}
        $secondary = @{"name" = "yourname"}

        $result = Merge-Hashtables -primary $primary -secondary $secondary

        $result | Should -BeLike @{"foo" = "bar"; "name" = "yourname"}
    }

    It "will merge two hashtables with duplicate keys" {

        $primary = @{"foo" = "bar"}
        $secondary = @{"name" = "yourname"; "foo" = "rab"}

        $result = Merge-Hashtables -primary $primary -secondary $secondary

        $result | Should -BeLike @{"foo" = "bar"; "name" = "yourname"}        
    }

}