Describe "Publish-GitHubRelease" -Tag "Foo" {

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
            Mock -CommandName Write-Error -MockWith {} -ParameterFilter { $Message.ToLower().Contains("unable to call api") }
            Mock -CommandName Write-Information -MockWith {}

            Mock -CommandName Invoke-WebRequest -MockWith { throw "Unable to call API" } -ParameterFilter { $Uri.AbsoluteUri -eq "https://api.github.com/repos/Ensono/pester/releases" }
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
                owner = "Ensono"
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

    Context "Errors will be thrown (artefact handling)" {

        BeforeEach {

            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        }

        AfterEach {

            Remove-Item -Path $testFolder -Recurse -Force
        }

        It "if file does not exist, should error" {

            Mock `
                -CommandName Get-ChildItem `
                -MockWith { throw } `
                -ParameterFilter { $Path -eq $testFolder -and $Filter -eq "foo.ps1" -and $ErrorAction -eq "Stop" } `
                -Verifiable

            Mock `
                -CommandName Get-ChildItem `
                -MockWith { } `
                -Verifiable

            Mock `
                -CommandName Write-Host `
                -MockWith { } `
                -Verifiable

            Mock `
                -CommandName Write-Error `
                -MockWith { "fail" >2 } `
                -Verifiable

            Mock `
                -CommandName Invoke-WebRequest `
                -MockWith { } `

            $splat = @{
                version = "100.98.99"
                commitId = "hjggh66"
                owner = "Ensono"
                apiKey = "1245356"
                repository = "pester"
                artifactsDir = $testfolder
                artifactsList = @("foo.ps1", "bar.ps1")
                publishRelease = $true
            }

            Publish-GitHubRelease @splat

            Should -InvokeVerifiable
            Should -Invoke -CommandName Write-Error -Times 1 -ParameterFilter { $Message -eq "One or more of the files can't be found..! See above for the files not found..." }
            Should -Invoke -CommandName Get-ChildItem -Times 2
            Should -Invoke -CommandName Invoke-WebRequest -Times 0
        }

        It "if file exists, will error if there is an issue talking to the GitHub API for artefact uploading" {

            Mock `
                -CommandName Get-ChildItem `
                -MockWith { $Filter } `
                -Verifiable

            Mock `
                -CommandName Write-Error `
                -MockWith { "fail" >2 } `
                -Verifiable

            Mock `
                -CommandName Invoke-WebRequest `
                -MockWith { return @{content = @"
                {
                    "upload_url": "https://api.github.com/repo/upload"
                }
"@
                } } `
                -ParameterFilter { $Uri.AbsoluteUri -eq "https://api.github.com/repos/Ensono/pester/releases" } `
                -Verifiable

            Mock `
                -CommandName Invoke-WebRequest `
                -MockWith { throw } `
                -Verifiable

            # bar.ps1 uploads successfully
            Mock `
                -CommandName Invoke-WebRequest `
                -MockWith { "uploaded" } `
                -ParameterFilter { $InFile -eq "bar.ps1" } `
                -Verifiable

            Mock `
                -CommandName Get-Item `
                -MockWith { "Some amazing content" } `
                -Verifiable

            $splat = @{
                version = "100.98.99"
                commitId = "hjggh66"
                owner = "Ensono"
                apiKey = "1245356"
                repository = "pester"
                artifactsDir = $testfolder
                artifactsList = @("foo.ps1", "bar.ps1")
                publishRelease = $true
            }

            Publish-GitHubRelease @splat

            Should -InvokeVerifiable
            Should -Invoke -CommandName Get-ChildItem -Times 2
            Should -Invoke -CommandName Invoke-WebRequest -Times 3
            Should -Invoke -CommandName Write-Error -Times 1 -ParameterFilter { $Message -eq "An error has occured, cannot upload foo.ps1: ScriptHalted" }
            Should -Invoke -CommandName Write-Error -Times 0 -ParameterFilter { $Message -eq "An error has occured, cannot upload bar.ps1: ScriptHalted" }
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

        It "with the specified artifacts and command line publishing" {

            $splat = @{
                version = "100.98.99"
                commitId = "hjggh66"
                owner = "Ensono"
                apiKey = "1245356"
                repository = "pester"
                artifactsDir = $testfolder
                publishRelease = $true
            }

            Publish-GitHubRelease @splat

            Should -Invoke -CommandName Invoke-WebRequest -Times 2
        }
        It "with the specified artifacts and environment variable publishing" {

            $env:PUBLISH_RELEASE = 'true'

            $splat = @{
                version = "100.98.99"
                commitId = "hjggh66"
                owner = "Ensono"
                apiKey = "1245356"
                repository = "pester"
                artifactsDir = $testfolder

            }

            Publish-GitHubRelease @splat

            $env:PUBLISH_RELEASE = $null

            Should -Invoke -CommandName Invoke-WebRequest -Times 2
        }
    }
}
