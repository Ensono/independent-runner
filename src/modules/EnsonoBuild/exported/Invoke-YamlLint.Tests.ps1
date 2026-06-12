Describe "Invoke-YamlLint" {

    BeforeAll {
        # Import test helpers
        . $PSScriptRoot/../../../../test/TestHelpers.ps1

        # Import function under test
        . $PSScriptRoot/Invoke-YamlLint.ps1

        # Include dependencies
        . $PSScriptRoot/../exported/Invoke-External.ps1

        # Create the testFolder
        $testFolder = New-TestDir

        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun   = $true
        }

        # Mock Write-Error so that when a function cannot find what it requires, the
        # error is generates can be caught
        Mock -CommandName Write-Error -MockWith { }

        Mock -CommandName Write-Information -MockWith { }

        # - Find-Command - return the name of the command that is required
        # Mock -Command Find-Command -MockWith { return $name }
    }

    AfterAll {
        if (Test-Path $testFolder) {
            Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "config file does not exist" {

        It "will error" {

            Invoke-YamlLint

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "base path does not exist" {

        BeforeAll {
            $basePath = New-TestDir
            $configFile = New-Item -Path (Join-Path -Path $basePath -ChildPath "yamllint.conf")
        }

        AfterAll {
            if (Test-Path $basePath) {
                Remove-Item -Path $basePath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "will error" {

            Invoke-YamlLint -BasePath doesnotexist -ConfigFile $configFile.FullName

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Python cannot be located" -Skip:$true {

        BeforeAll {
            $configFile = New-Item -Path (Join-Path -Path $testFolder -ChildPath "yamllint.conf")

            # Mock the Find-Command so that python cannot be found
            Mock -Command Find-Command -MockWith { return }
        }

        It "will error" {

            Invoke-YamlLint -ConfigFile $configFile.FullName

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "All validations pass" {

        BeforeAll {
            $testFolderForValidation = New-TestDir
            $configFile = New-Item -Path (Join-Path -Path $testFolderForValidation -ChildPath "yamllint.conf")

            $Session.commands.list = @()

            # Mock the find-command function to return python
            Mock -CommandName Find-Command -MockWith { return $name }
        }

        AfterAll {
            if (Test-Path $testFolderForValidation) {
                Remove-Item -Path $testFolderForValidation -Recurse -Force -ErrorAction SilentlyContinue
            }
        }


        It "will run the YamlLint command" {

            Invoke-YamlLint -ConfigFile $configFile.Fullname -BasePath $testFolderForValidation

            # Check that the list of installed Pip packages is being analysed
            $session.commands.list[0] | Should -BeLike ("*pip* freeze")

            # Ensure yamllint is being installed
            $session.commands.list[1] | Should -BeLike ("*pip* install yamllint")

            $session.commands.list[2] | Should -BeLike ("*python* -m yamllint -s -c {0} {1} {0}" -f $configFile.Fullname, $testFolderForValidation)

            Should -Invoke -CommandName Write-Information -Times 1
        }
    }
}
