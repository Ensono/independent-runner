

Describe "Invoke-Terraform" {

    BeforeAll {
        . $PSScriptRoot/Invoke-Terraform.ps1
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1
    
        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
    
        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }
    
        # Mock the Find-Command to return a valid path for the tool
        # This is so that the tool does not need to exist on the machine that is running the tests
        Mock -Command Find-Command -MockWith { return "terraform" }    
    
        # Mock Write-Error so that when a function cannot find what it requires, the
        # error is generates can be caught
        Mock -CommandName Write-Error -MockWith { }
    }

    Context "Initialise" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will error as there are no properties specified" {
            Invoke-Terraform -init
            Should -Invoke Write-Error
        }

        It "will initialise Terraform with the supplied argument" {

            # run the function to call terraform with some arguments for the backend
            Invoke-Terraform -init -Backend "key=tfstate,access_key=123456"

            # check that the generated command is correct
            $Session.commands.list[0] | Should -BeLike "*terraform* init -backend-config='key=tfstate' -backend-config='access_key=123456'"
        }

        It "will initialise Terraform with the supplied argument using a ; as the delimiter in the string" {

            # run the function to call terraform with some arguments for the backend
            Invoke-Terraform -init -Backend "key=tfstate;access_key=123456" -Delimiter ";"

            # check that the generated command is correct
            $Session.commands.list[0] | Should -BeLike "*terraform* init -backend-config='key=tfstate' -backend-config='access_key=123456'"
        }        

        It "will initialise Terraform using the environment variable for the backend config" {

            # Set the environment variable to use for the backend parameter
            $env:TF_BACKEND = "key=tfstate,access_key=123456"

            Invoke-Terraform -init -Backend "key=tfstate,access_key=123456"

            # check that the generated command is correct
            $Session.commands.list[0] | Should -BeLike "*terraform* init -backend-config='key=tfstate' -backend-config='access_key=123456'"    
            
            Remove-Item Env:\TF_BACKEND
        }

        It "will initialise Terraform using an array of backend arguments" {

            Invoke-Terraform -init -Backend @("key=tfstate", "access_key=123456")

            # check that the generated command is correct
            $Session.commands.list[0] | Should -BeLike "*terraform* init -backend-config='key=tfstate' -backend-config='access_key=123456'"              
        }
    }

    Context "Workspace" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "Will create a new workspace if it does not exist" {
            Invoke-Terraform -workspace -Arguments "pester" 
            $Session.commands.list[0] | Should -BeLike "*terraform* workspace select pester"
        }
    }

    Context "Custom" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "Will run an arbitary terraform command" {
            Invoke-Terraform -Custom -Arguments "destroy" 
            $Session.commands.list[0] | Should -BeLike "*terraform* destroy"
        }
    }

    Context "Plan" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will throw an error if a path to the terraform files has not been specified" {
            Invoke-Terraform -plan
            Should -Invoke Write-Error
        }

        It "will throw an error if the path to the TF files does not exist" {
            Invoke-Terraform -plan -Path "non/existent/path"
            Should -Invoke Write-Error
        }

        It "will run the plan command with the specified arguments" {
            Invoke-Terraform -plan -Path $testFolder -arguments "-input=false", "-out=tfplan"
            $Session.commands.list[0] | Should -BeLike "*terraform* plan -input=false -out=tfplan"
        }

        It "will run the plan command with the specified string" {
            Invoke-Terraform -plan -Path $testFolder -arguments "-input=false,-out=tfplan"
            $Session.commands.list[0] | Should -BeLike "*terraform* plan -input=false -out=tfplan"
        }
    }

    Context "Apply" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will throw an error if a path to the plan file has not been specified" {
            Invoke-Terraform -apply
            Should -Invoke Write-Error
        }

        It "will throw an error if the specified plan file does not exist" {
            Invoke-Terraform -apply -Path "tfplan"
            Should -Invoke Write-Error
        }
        
        It "will run the Terraform command to apply the specified plan" {

            # create the plan file to be used
            $planFile = New-Item -ItemType File -Path (Join-Path -Path $testFolder -ChildPath "tfplan")

            Invoke-Terraform -apply -Path $planFile
            $Session.commands.list[0] | Should -BeLike ("*terraform* apply {0}" -f $planFile)
        }
    }

    Context "Format" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will run commands to check that the TF files are correct" {
            Invoke-Terraform -Format

            $Session.commands.list[0] | Should -BeLike "*terraform* fmt -diff -check -recursive"
            # $Session.commands.list[1] | Should -BeLike "*terraform* init -backend=false; *terraform* validate"
        }
    }

    Context "Output" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()
        }

        It "will output TF state in JSON format" {
            Invoke-Terraform -output

            $Session.commands.list[0] | Should -BeLike "*terraform* output -json"
        }
    }

    Context "Validate" {

        BeforeEach {
            # Reset the commands list to an empty array
            $global:Session.commands.list = @()

            # create directory and file to mimic the output of the false backend init
            # these should be removed by the command
            $terraformDir = New-Item -ItemType Directory -Path (Join-Path -Path $testFolder -ChildPath ".terraform")
            $terraformLockFile = New-Item -ItemType File -Path (Join-Path -Path $testFolder -ChildPath ".terraform.lock.hcl")

        }

        It "will run the commands to perform validation checks" {

            Invoke-Terraform -Validate -Path $testFolder

            $Session.commands.list[0] | Should -BeLike "*terraform* init -backend=false"
            $Session.commands.list[1] | Should -BeLike "*terraform* validate"

            Test-Path -Path $terraformDir.FullName | Should -Be $false
            Test-Path -Path $terraformLockFile.FullName | Should -Be $false
        }
    }
}
