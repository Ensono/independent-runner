Describe "Build-URI" {

    BeforeAll {

        # Import the function being tests
        . $PSScriptRoot/Build-URI.ps1

        # Mocks
        # - Write-Warning
        Mock -CommandName Write-Warning -MockWith {}
    }

    It "will create a URI without a path and just a server" {

        Build-URI -server example.com | Should -Be "https://example.com"
    }

    It "will create a non-secure URI with a warning" {

        Build-URI -server example.com -notls | Should -Be "http://example.com"

        Should -Invoke -CommandName Write-Warning -Times 1
    }

    It "will build a URI using a custom port" {

        Build-URI -server example.com -port 8080 | Should -Be "https://example.com:8080"
    }

    It "will build a URI with the specified path" {

        Build-URI -server example.com -path "events" | Should -Be "https://example.com/events"
    }

    It "will return a URI with the query parameters correctly set" {

        Build-URI -server example.com -path "events" -query @{"name" = "beer"; "event" = "festival"} | Should -Be "https://example.com/events?name=beer&event=festival"
    }


}