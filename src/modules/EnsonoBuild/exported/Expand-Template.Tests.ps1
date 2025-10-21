
Describe "Expand-Template" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Expand-Template.ps1

        # Helper function to create test directories
        function New-TestDir {
            $tempPath = [System.IO.Path]::GetTempPath()
            $uniqueFolderName = "PesterTest_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
            $testFolderPath = [System.IO.Path]::Combine($tempPath, $uniqueFolderName)
            New-Item $testFolderPath -ItemType Directory -Force | Out-Null
            return $testFolderPath
        }

        # set environment variables to use
        $env:TEST_NAME = "pester"
        $env:TEST_COMPONENT = "core"

        # Create the testFolder
        $testFolder = New-TestDir
    }

    AfterAll {
        if (Test-Path $testFolder) {
            Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    it "will replace the variable in the template with the variable value" {

        $result = 'name: ${TEST_NAME}' | Expand-Template -Pipeline

        $result | Should -Be "name: pester"
    }

    it "will save the output of the render to a file" {
        

        $output = Join-Path -Path $testFolder -ChildPath "rendered.txt"
        'name: ${TEST_NAME}' | Expand-Template -target $output

        Test-Path -Path $output | Should -Be $true
        Get-Content -Path $output -Raw | Should -BeLike "name: pester*"
    }
    
    it "will take the contents of a template file and render it" {

        # Write template to a file to use
        $templateFile = Join-Path -Path $testFolder -ChildPath "template.txt"
        $content = 'component: ${TEST_COMPONENT}'
        Set-Content -Path $templateFile -Value $content

        $result = Expand-Template -Path $templateFile -Pipeline

        $result | Should -BeLike "component: core*"
    }

    it "uses values specified on the command line" {

        $result = 'external: ${EXTERNAL}' | Expand-Template -a @{"external" = "azure" } -Pipeline

        $result | Should -Be "external: azure"
    }
}
