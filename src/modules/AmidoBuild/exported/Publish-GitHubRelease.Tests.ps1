Describe "Publish-GitHubRelease" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Publish-GitHubRelease.ps1

        # Include dependent functions
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1
    }

    Context "Errors will be thrown" {

        BeforeAll {

            # Mock commands
            Mock -CommandName Write-Error -MockWith {} -ParameterFilter { $Message.ToLower().Contains("version") }
            Mock -CommandName Write-Error -MockWith {} -ParameterFilter { $Message.ToLower().Contains("unable to call api")}
            Mock -CommandName Write-Information -MockWith {} -ParameterFilter { $Message.ToLower().Contains("publishrelease parameter not specified")}

            Mock -CommandName Invoke-WebRequest -MockWith { throw "Unable to call API" } -ParameterFilter { $Uri.AbsoluteUri.ToLower().Contains("api.github.com/repos/amido/pester")}
        }

        BeforeEach {

            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

            # Create a dummy file for release
            New-Item -ItemType File -Path ([IO.Path]::Combine($testFolder, "module.psm1")) | Out-Null
        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force
        }

        It "if publishRelease parameter has not been set" {

            Publish-GitHubRelease

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "if publishRelease parameter has been set to false" {

            Publish-GitHubRelease -publishRelease $false

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "if parameters have not been set" {

            Publish-GitHubRelease -publishRelease $true

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will error if there is an issue talking to the GitHub API" {

            $splat = @{
                version = "100.98.99"
                commitId = "hjggh66"
                owner = "amido"
                apiKey = "1245356"
                repository = "pester"
                artifactsDir = $testfolder
                publishRelease = $true
            }

            Publish-GitHubRelease @splat

            Should -Invoke -CommandName Invoke-WebRequest -Times 1
            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Release is created" {

        BeforeAll {

            # Mock commands

            # Mock the Invoke-WebRequest cmdlet so that it returns a valid object, which contains
            # valid JSON strng
            Mock -CommandName Invoke-WebRequest -MockWith { 
                return @{content = @"
    {
        "upload_url": "https://api.github.com/repo/upload"
    }
"@
                }
             }
        }

        BeforeEach {

            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

            # Create a dummy file for release
            New-Item -ItemType File -Path ([IO.Path]::Combine($testFolder, "module.psm1")) | Out-Null
        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force
        }

        It "with the specified artifacts" {

            $splat = @{
                version = "100.98.99"
                commitId = "hjggh66"
                owner = "amido"
                apiKey = "1245356"
                repository = "pester"
                artifactsDir = $testfolder
                publishRelease = $true
            }

            Publish-GitHubRelease @splat

            Should -Invoke -CommandName Invoke-WebRequest -Times 2
        }
    }
}
