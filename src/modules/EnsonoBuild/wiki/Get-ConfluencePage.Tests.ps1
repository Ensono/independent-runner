
Describe "Get-ConfluencePage" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Get-ConfluencePage.ps1

        # Import dependencies
        . $PSScriptRoot/../api/Invoke-API.ps1
        . $PSScriptRoot/../command/Stop-Task.ps1
        
        # Mock functions
        Mock -Command Stop-Task -MockWith {}
        Mock -Command Write-Information -MockWith {}
    }

    Context "Incorrect URL" {

        BeforeAll {

            # Mock Invoke-API so that the correct status code can be returned
            Mock -CommandName Invoke-API -MockWith {
                $message = [System.Net.Http.HttpResponseMessage]::new()
                $message.StatusCode = [System.Net.HttpStatusCode]::NotFound
                $ex = [Microsoft.PowerShell.Commands.HttpResponseException]::new("404", $message)

                $ex
            }
        }

        It "will stop because the URL cannot be found" {

            Get-ConfluencePage -Url "https://domain.not.found" -Credentials "" | Out-Null

            Should -Invoke -CommandName Stop-Task -Times 1
            Should -Invoke -CommandName Write-Information -Times 1
        }
    }

    Context "Confluence page does not exist" {

        BeforeAll {

            # Mock the Invoke-API so that a valid Confluence response is returned
            Mock -CommandName Invoke-Api -MockWith {

                return @"
{
    "results": []
}
"@
            }
        }

        It "will return an object stating page should be created" {

            $res = Get-ConfluencePage -Url "https://myorg.atlassian.net/wikli/rest/api/content?spaceKey=AD&title=pester"

            $res.Version | Should -Be 1
            $res.Create | Should -Be $true

            Should -Invoke -CommandName Write-Information -Times 1
        }
    }

    Context "Confluence page details will be returned" {

        BeforeAll {

            # Mock the Invoke-API to get the page requested
            Mock -CommandName Invoke-Api -MockWith {
                return @"
{
    "results": [
        {
            "id": "987654",
            "version": {
                "number": 2
            }
        }
    ]
}
"@ 
            } -ParameterFilter {
                $url -like "*/content?spaceKey*"
            }

            # Mock the Invoke-API to give the necessary response to get a property page
            Mock -CommandName Invoke-Api -MockWith {

                return @{"Content" = @"
{
    "results": [
        {
            "key": "checksum",
            "value": [
                "123456"
            ]
        }
    ]
}
"@}
            } -ParameterFilter {
                $url -like "*property*"
            }
        }

        It "will return a page with all the details" {

            $details = Get-ConfluencePage -Url "https://myorg.atlassian.net/wikli/rest/api/content?spaceKey=AD&title=pester" -Credentials ""

            $details.ID | Should -Be "987654"
            $details.Version | Should -Be 2
            $details.Checksum | Should -Be "123456"
        }
    }
}