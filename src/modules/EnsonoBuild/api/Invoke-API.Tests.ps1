
Describe "Invoke-API" {

    BeforeAll {
        # Include the function under test
        . $PSScriptRoot/Invoke-API.ps1
    }

    Context "When a call is made to a bad host or path" {

        BeforeAll {

            # Mock Invoke-WebRequest so that it will return a page not found
            Mock Invoke-WebRequest {

                $message = [System.Net.Http.HttpResponseMessage]::new()
                $message.StatusCode = [System.Net.HttpStatusCode]::NotFound
                $ex = [Microsoft.PowerShell.Commands.HttpResponseException]::new("404", $message)

                throw $ex
            } -ParameterFilter {
                $Method -eq "Get"
            }

            # Set the splat for the Invoke-API parameters
            $splat = @{
                url = "https://domain.not.found.com/unknown.html"
            }

        }

        It "Invoke-API should not run successfully" {
            $res = Invoke-API @splat
            $res | Should -BeOfType [System.Exception]
        }

        It "Invoke-API should throw a 404 error" {

            $res = Invoke-API @splat
            $res.Response.StatusCode | Should -Be 404
            $res.Response.ReasonPhrase | Should -Be "Not Found"

        }
    }

    Context "Pages are called with basic authentication" {

        BeforeAll {

            Mock Invoke-WebRequest -MockWith {

                # Return the headers so they can be checked
                return $Credential
            }
        }

        It "Credentials will be specified" {
            $creds = Invoke-API -credentials "pester:tests" -authtype "basic"

            $creds | Should -BeOfType [System.Management.Automation.PSCredential]
        }
    }
}
