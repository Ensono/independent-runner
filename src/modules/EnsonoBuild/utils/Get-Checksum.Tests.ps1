Describe "Get-Checksum" {

    BeforeAll {

        # Include the function under test
        . $PSScriptRoot/Get-Checksum.ps1

        # Helper function to create test directories
        function New-TestDir {
            $tempPath = [System.IO.Path]::GetTempPath()
            $uniqueFolderName = "PesterTest_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
            $testFolderPath = [System.IO.Path]::Combine($tempPath, $uniqueFolderName)
            New-Item $testFolderPath -ItemType Directory -Force | Out-Null
            return $testFolderPath
        }

        # Create the testFolder
        $testFolder = New-TestDir
        
        $testFile = [IO.Path]::Combine($testFolder, "content.txt")
        Set-Content -Path $testFile -Value "Hello World!" -NoNewline
    }

    AfterAll {
        if (Test-Path $testFolder) {
            Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
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