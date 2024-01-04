Describe "Get-Checksum" {

    BeforeAll {

        # Include the function under test
        . $PSScriptRoot/Get-Checksum.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        
        $testFile = [IO.Path]::Combine($testFolder, "content.txt")
        Set-Content -Path $testFile -Value "Hello World!" -NoNewline
    }

    It "will get null if null is provided" {

        Get-Checksum | Should -BeNullOrEmpty
    }

    It "will return the checksum of a string" {

        Get-Checksum -content "Hello World!" | Should -Be "ED076287532E86365E841E92BFC50D8C"
    }

    It "will provide the checksum of the contents of a file" {

        Get-Checksum -content $testFile | Should -Be "ED076287532E86365E841E92BFC50D8C"
    }
}