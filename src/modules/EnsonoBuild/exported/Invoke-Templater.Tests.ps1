Describe "Invoke-Templater" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Invoke-Templater.ps1

        # Import dependencies
        . $PSScriptRoot/Expand-Template.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # create two files to pass to the function
        # one with valid PS data and one without
        $deploymentData = '@(
            @{
                displayName = "AppDeployment"
                template = "templates/base_deploy.yml"
                vars = @{
                  dns_pointer = "${ENV_NAME}-${DOMAIN}.${BASE_DOMAIN}"
                }
            }
        )'

        $terraformData = @"
        {
            "sa_name": {
                "sensitive": false,
                "type": "string",
                "value": "azurestorageacc"
            }
        }
"@

        $invalidFile = New-Item -Path (Join-Path -Path $testFolder -ChildPath "invalid.txt") -Value "foobar"
        $validFile = New-Item -Path (Join-Path -Path $testFolder -ChildPath "valid.txt") -Value $deploymentData
        $templateDir = New-Item -ItemType Directory -Path (Join-Path -Path $testFolder -ChildPath "templates")
        $deployFile = New-Item -Path (Join-Path -Path $templateDir -ChildPath "base_deploy.yml") -Value 'url: https://${dns_pointer}`nsa_name: ${sa_name}'

        # create JSON file to use to represent Terraform output data
        $tfOutputs = New-Item -Path (Join-Path -Path $testFolder -ChildPath "tfdata.json") -Value $terraformData

        # Mock functions that are called
        # - Write-Error - mock this internal function to check that errors are being raised
        Mock -Command Write-Error -MockWith { return $MessageData } -Verifiable

        # - Write-Information
        Mock -Command Write-Information -MockWith { return $MessageData } -Verifiable
    

    }

    Context "replaces values in templates" {

        BeforeAll {

            # Create env var that can be checked for
            $env:PESTER_TEMPLATER = "foobar"

            # Mock the Expand-Template so that the internals of the function can be tested
            # Mock -CommandName Expand-Template -MockWith {}

            # set environment variables
            $env:ENV_NAME = "pester"
            $env:DOMAIN = "example"
            $env:BASE_DOMAIN = "example.com"
        }

        AfterAll {

            Remove-Item env:\PESTER_TEMPLATER
            Remove-Item env:\ENV_NAME
            Remove-Item env:\DOMAIN
            Remove-Item env:\BASE_DOMAIN
        }

        BeforeEach {

            $renderedFile = [IO.Path]::Combine($testFolder, "templates", "deploy.yml")
        }

        AfterEach {
            If (Test-Path -Path $renderedFile) {
                Remove-Item -Path $renderedFile
            }
        }

        It "throws an error as the path is a folder" {

            Invoke-Templater -Path $testFolder

            Should -Invoke -CommandName Write-Error -Times 1

            # Get-Variable -Name PESTER_TEMPLATER -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It "thows and error because the file does not contain valid data" {

            Invoke-Templater -Path $invalidFile.FullName

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will create a rendered file" {

            # Pass the path to the file for the tfoutputs
            # the parameter allows for a path or a valid JSON object to be passed
            Invoke-Templater -Path $validFile.FullName -BaseDir $testFolder -tfdata $tfOutputs.FullName

            # Check that the rendered file exists
            Test-Path -Path $renderedFile | Should -Be $true

            # Check the contents of the file
            (Get-Content -Path $renderedFile -Raw).Trim() | Should -Be "url: https://pester-example.example.com`nsa_name: azurestorageacc"

            # Check that Write-Information is called to state which template has been rendered
            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "can accept data from the pipeline" {

            # Send the tfoutputs into the command using the pipeline
            $terraformData | Invoke-Templater -Path $validFile.FullName -BaseDir $testFolder

            # Check that the rendered file exists
            Test-Path -Path $renderedFile | Should -Be $true

            # Check the contents of the file
            (Get-Content -Path $renderedFile -Raw).Trim() | Should -Be "url: https://pester-example.example.com`nsa_name: azurestorageacc"

            # Check that Write-Information is called to state which template has been rendered
            Should -Invoke -CommandName Write-Information -Times 1
        }
    }
}