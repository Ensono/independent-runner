
Describe "Confirm-TrunkBranch" {

    BeforeAll {

        # Include the function under test
        . $PSScriptRoot/Confirm-TrunkBranch.ps1

        # Mocks
        Mock -Command Write-Warning -MockWith { }

    }

    AfterAll {

        Remove-Item env:\TRUNK_NAMES
    }

    Context "Git is used" {

        Context "Common name is used for trunk branch" {

            BeforeAll {
                Mock -Command Invoke-Expression -MockWith { return "main" }
            }

            BeforeEach {
                $env:TRUNK_NAMES = ""
            }

            it "will confirm on a trunk branch (main)" {

                $result = Confirm-TrunkBranch

                $result | Should -Be $true
            }

            it "will return a negative for branch (feature/add-feature)" {

                $result = Confirm-TrunkBranch -name "feature/add-feature"

                $result | Should -Be $false
            }

            it "will use name of branch from environment variable" {

                $env:TRUNK_NAMES = "bug/fix-crash"

                Confirm-TrunkBranch | Should -Be $false
            }
        }

        Context "A specific branch has been set as the trunk branch" {

            BeforeAll {
                Mock -Command Invoke-Expression -MockWith { return "release" }
            }

            it "will confirm on a trunk branch (release)" {

                $env:TRUNK_NAMES = "release"
                $result = Confirm-TrunkBranch

                $result | Should -Be $true
            }
        }
    }

    Context "Unsupported SCS is used" {

        It "will display a warning" {

            $result = Confirm-TrunkBranch -scs mercurial

            $result | Should -Be $false
            Should -Invoke Write-Warning -Times 1
        }
    }
}