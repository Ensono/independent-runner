Describe "Publish-Confluence" {

    BeforeAll {

        # Include the function under test
        . $PSScriptRoot/Publish-Confluence.ps1

        # Include dependencies
        . $PSScriptRoot/../api/Invoke-Api.ps1
        . $PSScriptRoot/../command/Stop-Task.ps1
        . $PSscriptRoot/../utils/Build-Uri.ps1
        . $PSscriptRoot/../utils/Confirm-Parameters.ps1
        . $PSscriptRoot/../utils/Get-Checksum.ps1
        . $PSScriptRoot/../wiki/Get-ConfluencePage.ps1
        . $PSScriptRoot/../wiki/Get-PageImages.ps1

        # Mock functions
        Mock -Command Stop-Task -MockWith {}
        Mock -Command Write-Information -MockWith {}

        Mock -Command Confirm-Parameters -MockWith { $true }

        Mock -CommandName Invoke-Api -MockWith {
            return ""
        } -ParameterFilter {
           $method -eq "PUT"
        }

        # Invoke-Api mocks
        Mock -CommandName Invoke-Api -MockWith {
            return @{
                Content = @"
{
    "result":
        {
            "id": "123456",
            "version": {
                "number": 2
            }
        }
}
"@
                    }
        } -ParameterFilter {
            $method -ieq "POST" -and 
            $body -ilike "*Initial page created*"
        }

        Mock -CommandName Invoke-Api -MockWith {
            return ""
        } -ParameterFilter {
            $method -eq "PUT" -and $url -like "*/property/checksum*"
        }        
    }

    Context "Adding a new page" {

        BeforeAll {

            # - Get-Confluence page mocks
            Mock -CommandName Get-ConfluencePage -MockWith {
                return @{
                    Create = $true
                    Version = 1
                }
            }

            # - Get-PageImage mocks
            Mock -CommandName Get-PageImages -MockWith {
                @()
            }            
        }

        It "will publish content" {

            Publish-Confluence -title "Pester Tests" -space "AD" -body "Some new text" -server "confluence.server" -credentials "pester:tests"

            Should -Invoke -CommandName Confirm-Parameters -Times 1
            Should -Invoke -CommandName Get-ConfluencePage -Times 1
            Should -Invoke -CommandName Invoke-Api -Times 2
            
        }
    }

    Context "Updating a page with images" {

        BeforeAll {

            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
            $testImg = [IO.Path]::Combine($testFolder, "myimage.png")
            New-Item -ItemType File -Path $testImg | Out-Null

            Mock -CommandName Get-ConfluencePage -MockWith {
                return @{
                    Create = $false
                    Version = 2
                }
            }

            Mock -CommandName Get-PageImages -MockWith {
                return @(
                    @{
                        local = "myimage.png"
                        remote = ""
                    }
                )
            }

            Mock -CommandName Invoke-Api -MockWith {

            } -ParameterFilter {
                $Method -eq "POST" -and
                $ContentType -eq "multipart/form-data"
            }
        }

        It "will correctly update the paths to images" {

            $splat = @{
                title = "Pester Tests"
                space = "AD"
                body = 'An image for the page <img src="myimage.png">'
                server = "confluence.server"
                credentials = "pester:tests"
                path = $testFolder
            }

            Publish-Confluence @splat

            Should -Invoke -CommandName Confirm-Parameters -Times 1
            Should -Invoke -CommandName Get-ConfluencePage -Times 1
            Should -Invoke -CommandName Invoke-Api -Times 3
        }
    }
}