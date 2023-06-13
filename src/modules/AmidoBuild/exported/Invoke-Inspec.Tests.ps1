
Describe "Invoke-Inspec" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Invoke-Inspec.ps1

        # Import dependent functions
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
        . $PSScriptRoot/../command/Stop-Task.ps1
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1

        # Import dependent classes
        . $PSScriptRoot/../classes/StopTaskException.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }

        function inspec { }

        # Mock the Find-Command to return a valid path for the tool
        # This is so that the tool does not need to exist on the machine that is running the tests
        Mock -Command Find-Command -MockWith { return "inspec" }

        # Mock commands to check that they are being called
        Mock -CommandName Write-Error -MockWith { }

        Mock -CommandName inspec -MockWith { }

        Mock -Verifiable -CommandName Invoke-External -MockWith { }
    }

    Context "Initialize" {

        It "will error if no path has been specified" {
            { Invoke-Inspec -init } | Should -Throw "Path to the Inspec test files must be specified`nTask failed due to errors detailed above"

            Should -Invoke Write-Error -Exactly 1
            Should -Invoke -CommandName Invoke-External -Exactly 0
        }

        It "will error if the path to the files does not exist" {
            { Invoke-Inspec -init -path "pester" } | Should -Throw "Specfied path for Inspec files does not exist: pester`nTask failed due to errors detailed above"

            Should -Invoke Write-Error -Exactly 1
            Should -Invoke -CommandName Invoke-External -Exactly 0
        }

        It "will initialise inspec" {
            Invoke-Inspec -init -path $testFolder

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec init") }
        }
    }

    Context "Execute" {

        BeforeEach {
            Remove-Item env:\INSPEC_ARGS -ErrorAction SilentlyContinue
        }

        It "will execute the tests for the specified cloud" {
            Invoke-Inspec -exec -path $testfolder -cloud azure

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec exec . -t azure:// --reporter cli") }
        }

        it "will append any extra arguments to the command, if they are supplied as a string" {
            Invoke-Inspec -exec -path $testfolder -cloud azure -args "--input resource_group_name=myresources-euw"

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec exec . -t azure:// --reporter cli --input resource_group_name=myresources-euw") }
        }

        it "will append any extra arguments to the command, if they are supplied as a command delimited list" {
            Invoke-Inspec -exec -path $testfolder -cloud azure -args "--input", "resource_group_name=myresources-euw"

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec exec . -t azure:// --reporter cli --input resource_group_name=myresources-euw") }
        }

        it "will append any extra arguments to the command, if they are set as an environment variable" {

            # Set the environment variable
            $env:INSPEC_ARGS = "--input resource_group_name=myresources-euw"

            Invoke-Inspec -exec -path $testfolder -cloud azure

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec exec . -t azure:// --reporter cli --input resource_group_name=myresources-euw") }
        }

        it "will append a reporter to the command if an output path is provided" {

            # Determine the output path based on the OS
            if ($isWindows) {
                $output = [IO.Path]::Combine($env:SystemDrive, "output", "tests")
            } else {
                $output = [IO.Path]::Combine("/", "output", "tests")
            }
            $expected = [IO.Path]::Combine($output, "inspec_tests_azure_folder.xml")

            Invoke-Inspec -exec -path $testfolder -cloud azure -output $output

            $command = "inspec exec . -t azure:// --reporter cli junit2:{0}" -f $expected

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @($command) }
        }

        it "will add the arguments to the command in the correct order" {

            Invoke-Inspec -exec -path $testfolder -cloud azure -arguments "--input resource_group_name=pester_resources --overwrite"

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec exec . -t azure:// --reporter cli --overwrite --input resource_group_name=pester_resources") }
        }
    }

    Context "Vendor" {

        it "will vendor the profile in the specified path" {

            Invoke-Inspec -vendor -path $testfolder

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec vendor . ") }

        }

        it "will overwrite existing vendor profile if specified" {

            Invoke-Inspec -vendor -path $testfolder -args "--overwrite"

            # check that the generated command is correct
            Should -Invoke -CommandName Invoke-External -Exactly 1 -ParameterFilter { $commands -eq @("inspec vendor . --overwrite") }
        }
    }
}
