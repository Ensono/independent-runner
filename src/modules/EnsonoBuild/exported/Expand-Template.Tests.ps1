
Describe "Expand-Template" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Expand-Template.ps1

        # set environment variables to use
        $env:TEST_NAME = "pester"
        $env:TEST_COMPONENT = "core"

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
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

        $result = 'external: ${EXTERNAL}' | Expand-Template -a @{"external" = "azure"} -Pipeline

        $result | Should -Be "external: azure"
    }
}