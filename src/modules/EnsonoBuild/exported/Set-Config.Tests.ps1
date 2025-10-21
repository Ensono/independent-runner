
Describe "Set-Config" {

    BeforeAll {
        # Helper function to create test directories
        function New-TestDir {
            $tempPath = [System.IO.Path]::GetTempPath()
            $uniqueFolderName = "PesterTest_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
            $testFolderPath = [System.IO.Path]::Combine($tempPath, $uniqueFolderName)
            New-Item $testFolderPath -ItemType Directory -Force | Out-Null
            return $testFolderPath
        }

        # Include the function under test
        . $PSSCriptRoot/Set-Config.ps1

        $global:Session = @{
            commands = @{
                list = @()
                file = ""
            }
            dryrun   = $true
        }

        # Mock commands
        # Write-Error - so that when a function cannot find what it requires, the
        # error is generates can be caught
        Mock -CommandName Write-Error -MockWith { }
    }

    Context "Parent path for log file does not exist" {

        It "will error" {
            Set-Config -CommandPath (Join-Path -Path "does" -ChildPath "notexist")

            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Log path is valid" {

        BeforeAll {
        # Helper function to create test directories
        function New-TestDir {
            $tempPath = [System.IO.Path]::GetTempPath()
            $uniqueFolderName = "PesterTest_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
            $testFolderPath = [System.IO.Path]::Combine($tempPath, $uniqueFolderName)
            New-Item $testFolderPath -ItemType Directory -Force | Out-Null
            return $testFolderPath
        }
            
            # Create the testFolder
            $testFolder = New-TestDir

            $cmdLogFile = [IO.Path]::Combine($testFolder, "cmdlog.txt")
        }

        It "will configure the session" {

            Set-Config -CommandPath $cmdLogFile

            $session.commands.file | Should -Be $cmdLogFile
        }
    }
}

