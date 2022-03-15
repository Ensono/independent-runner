

Describe "Publish-NugetPackage" {

    BeforeAll {
        . $PSScriptRoot/Publish-NugetPackage.ps1
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1

        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }
    
        Mock -CommandName Write-Error -Mockwith {}
        Mock -CommandName Write-Information -MockWith {}
        Mock -Command Find-Command -MockWith { return "dotnet" }

    }

    AfterAll {

        Remove-Variable -Name Session -Scope global
    }

    Context "No PUBLISH_RELEASE env var or parameter" {
        BeforeEach {
            $env:PUBLISH_RELEASE = $null
            Publish-NugetPackage
        }

        It "should return" {
            Should -Invoke -CommandName Write-Information -Times 1
        }
    }

    Context "With PUBLISH_RELEASE env var but no API Key" {
        BeforeEach {
            $env:PUBLISH_RELEASE = "true"
            Publish-NugetPackage
        }

        It "should error" {
            Should -Invoke -CommandName Write-Error -Times 1
        }
        AfterEach {
            $env:PUBLISH_RELEASE = $null
        }
    }

    Context "With publishRelease parameter but no API Key" {
        BeforeEach {
            Publish-NugetPackage -publishRelease $true
        }

        It "should error" {
            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "With publishRelease parameter and API Key parameter" {
        BeforeEach {
            Publish-NugetPackage -publishRelease $true -APIKey "1234"
        }

        It "will attempt to Push packages" {
            $Session.commands.list[0] | Should -BeLike "*dotnet*"
        }
    }

}

