Describe "Invoke-YamlLint" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Invoke-YamlLint.ps1

        # Include dependencies
        . $PSScriptRoot/../command/Invoke-External.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }

        # Mock Write-Error so that when a function cannot find what it requires, the
        # error is generates can be caught
        Mock -CommandName Write-Error -MockWith { }

        Mock -CommandName Write-Information -MockWith { }

        # - Find-Command - return the name of the command that is required
        # Mock -Command Find-Command -MockWith { return $name }        
    }

    Context "config file does not exist" {

        It "will error" {

            Invoke-YamlLint

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "base path does not exist" {

        BeforeAll {

            $configFile = New-Item -Path (Join-Path -Path $testFolder -ChildPath "yamllint.conf")
        }

        It "will error" {

            Invoke-YamlLint -BasePath doesnotexist -ConfigFile $configFile.FullName

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Python cannot be located" {


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

        BeforeEach {
            $configFile = New-Item -Path (Join-Path -Path $testFolder -ChildPath "yamllint.conf")

            $Session.commands.list = @()

            # Mock the find-command function to return python
            Mock -CommandName Find-Command -MockWith { return $name }
        }


        It "will run the YamlLint command" {

            Invoke-YamlLint -ConfigFile $configFile.Fullname -BasePath $testFolder

            # Check that the list of installed Pip packages is being analysed
            $session.commands.list[0] | Should -BeLike ("*pip* freeze")

            # Ensure yamllint is being installed
            $session.commands.list[1] | Should -BeLike ("*pip* install yamllint")

            $session.commands.list[2] | Should -BeLike ("*python* -m yamllint -sc {0} {1} {0}" -f $configFile.Fullname, $testFolder)

            Should -Invoke -CommandName Write-Information -Times 1
        }
    }
}