Describe "Get-AuthHeader" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Get-AuthHeader.ps1

    }

    Context "header will be generated" {

        it "will return basic auth header" {

            $secure = ConvertTo-SecureString -string "pester@12345" -AsPlainText -Force
            $header = Get-AuthHeader -credentials $secure -encode

            $header | Should -Be "Authorization: Basic cABlAHMAdABlAHIAQAAxADIAMwA0ADUA"
        }

        it "will return a bearer header" {

            $secure = ConvertTo-SecureString -string "apikey123456" -AsPlainText -Force
            $header = Get-AuthHeader -credentials $secure -authtype "bearer"

            $header | Should -Be "Authorization: Bearer apikey123456"
        }
    }
}