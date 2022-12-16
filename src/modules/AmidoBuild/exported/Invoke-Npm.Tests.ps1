Describe "Invoke-Npm" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Invoke-Npm.ps1

        # Import the dependenices for the function under test
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1

        # Mock functions that are called
        # - Find-Command - return the name of the command that is required
        Mock -Command Find-Command -MockWith { return $name }

        # - Write-Information - mock this internal function to check that the working directory is being defined
        Mock -Command Write-Information -MockWith { return $MessageData } -Verifiable

        # - Write-Error - mock this internal function to check that errors are being raised
        Mock -Command Write-Error -MockWith { return $MessageData } -Verifiable

        # Set some sensible defaults
        $headSHA = "122015c9e8176ed5f522b5edfd404483706df74807a07f8525fa1f4babdf79d6"
        $baseSHA = "b2fb322f3b52a7d5eebf5d90c816a12cccf6b13236602603a4948c178e518898"
    }

    BeforeEach {

        # Create a session object so that the Invoke-External function does not
        # execute any commands but the command that would be run can be checked
        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }
    }    

    Context "Install" {

        It "will install the project dependenices" {

            Invoke-Npm -Install

            $Session.commands.list[0] | Should -BeLike "*npm* i"

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "will perform a clean install of project dependencies" {

            Invoke-Npm -Install -Clean

            $Session.commands.list[0] | Should -BeLike "*npm* ci"

            Should -Invoke -CommandName Write-Information -Times 1
        }
    }

    Context "Build" {

        It "will throw an error if the Base SHA checksum is not specified" {

            Invoke-Npm -Build

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will attempt to run all commands if no tasks are specified" {

            Invoke-Npm -Build -BaseSHA $baseSHA -HeadSHA $headSHA

            $Session.commands.list.Count | Should -Be 8

            $Session.commands.list[0] | Should -BeLike "*npx* nx-cloud start-agent"
            $Session.commands.list[1] | Should -BeLike "*npx* nx-cloud start-ci-run --stop-agents-after=`"build`" --agent-count=3"
            $Session.commands.list[2] | Should -BeLike "*npx* nx-cloud record -- npx nx workspace-lint"
            $Session.commands.list[3] | Should -BeLike ("*npx* nx-cloud record -- npx nx format:check --base={0} --head={1}" -f $baseSHA, $headSHA)
            $Session.commands.list[4] | Should -BeLike ("*npx* nx affected --base={0} --head={1} --target=lint --parallel=3" -f $baseSHA, $headSHA)
            $Session.commands.list[5] | Should -BeLike ("*npx* nx affected --base={0} --head={1} --target=test --parallel=3 --ci --code-coverage" -f $baseSHA, $headSHA)
            $Session.commands.list[6] | Should -BeLike ("*npx* nx affected --base={0} --head={1} --target=build --parallel=3" -f $baseSHA, $headSHA)
            $Session.commands.list[7] | Should -BeLike "*npx* nx-cloud stop-all-agents"
        }

        It "will only run the specified tasks" {

            Invoke-Npm -Build -BaseSHA $baseSHA -HeadSHA $headSHA -tasks "workspace,build"

            $Session.commands.list.Count | Should -Be 5

            $Session.commands.list[0] | Should -BeLike "*npx* nx-cloud start-agent"
            $Session.commands.list[1] | Should -BeLike "*npx* nx-cloud start-ci-run --stop-agents-after=`"build`" --agent-count=3"
            $Session.commands.list[2] | Should -BeLike "*npx* nx-cloud record -- npx nx workspace-lint"
            $Session.commands.list[3] | Should -BeLike ("*npx* nx affected --base={0} --head={1} --target=build --parallel=3" -f $baseSHA, $headSHA)
            $Session.commands.list[4] | Should -BeLike "*npx* nx-cloud stop-all-agents"
        }
    }

    Context "Custom" {

        It "will execut NPM with the specified arguments" {

            Invoke-Npm -Npm -Arguments "install"

            $Session.commands.list.Count | Should -Be 1

            $Session.commands.list[0] | Should -BeLike "*npm* install"
        }
    }
 }