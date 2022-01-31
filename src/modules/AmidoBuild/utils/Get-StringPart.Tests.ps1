
Describe "Get-StringPart" {

    BeforeAll {
        . $PSScriptRoot/Get-StringPart.ps1

        $phrase = "The quick lazy fox jumped over the brown cow"
    }

    it "should throw an error if the item is less than 1" {

        Mock Write-Error -MockWith { }

        $result = Get-StringPart -phrase $phrase -item 0

        Assert-MockCalled Write-Error -Exactly 1 -Scope It

        $result | Should -Be $null
    }

    It "should throw an error as item is greater than the parts" {

        Mock Write-Error -MockWith { }

        $result = Get-StringPart -phrase $phrase -item 10

        Assert-MockCalled Write-Error -Exactly 1 -Scope It

        $result | Should -Be $null
    }

    It "should return the first string in the phrase" { 

        $result = Get-StringPart -phrase $phrase -item 1

        $result | Should -Be "The"
    }    

    It "should return the whole phrase if the delimiter is changed and it does not exist" {

        $result = Get-StringPart -phrase $phrase -item 1 -delimiter ";"

        $result | Should -Be $phrase
    }

    it "should return the correct partif the delimiter is changed to match the phase" {

        $modified = $phrase -replace " ", "_"

        $result = Get-StringPart -phrase $modified -item 1 -delimiter "_"

        $result | Should -Be "The"
    }
}