

Describe "Invoke-Terraform" {

    $TF_BACKEND

    BeforeAll {
        . $PSScriptRoot/Invoke-Terraform.ps1
        . $PSScriptRoot/../exported/Invoke-External.ps1
        . $PSScriptRoot/../classes/StopTaskException.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName

        # Create a dummy version of Terrform to use
        $terraform = New-Item -ItemType File -Path ([IO.Path]::Combine($testFolder, "1.5.1", "bin", "terraform")) -Force

        # This test uses this variable, clear if user has set it...
        if ($env:TF_BACKEND) {
            $TF_BACKEND = $env:TF_BACKEND
            Remove-Item Env:\TF_BACKEND
        }

        # Mock the Find-Command to return a valid path for the tool
        # This is so that the tool does not need to exist on the machine that is running the tests
        Mock -Command Find-Command -MockWith { return "terraform" }

        Mock -CommandName Write-Error -MockWith { }
        # Mock -CommandName Write-Warning -MockWith { }
    }

    AfterAll {
        # Restore the user's TF_BACKEND variable after all the tests
        $env:TF_BACKEND = $TF_BACKEND
    }

    Context "Terraform Version" {
        It "will error as the version does not exist" {

            Mock `
                -Command Invoke-External `
                -MockWith { }

            # run the function to call terraform with some arguments for the backend
            Invoke-Terraform -init -Backend "key=tfstate,access_key=123456" -Version 1.7.1

            Should -Invoke Write-Error -Exactly 1 -ParameterFilter { $Message -like "Specified Terraform version does not exist*" -and $ErrorAction -eq "Stop" }
            Should -Invoke Invoke-External -Exactly 0
        }

        It "will initialise Terraform with the supplied argument and specifid version of Terraform" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -like "*init -backend-config='key=tfstate' -backend-config='access_key=123456'" }

            # run the function to call terraform with some arguments for the backend
            Invoke-Terraform -init -Backend "key=tfstate,access_key=123456" -Prefix $testFolder -Version 1.5.1

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }

    Context "Initialise" {
        It "will error as there are no properties specified" {
            Mock `
                -Command Invoke-External `
                -MockWith { }

            Invoke-Terraform -init

            Should -Invoke Write-Error -Exactly 1 -ParameterFilter { $Message -eq "No properties have been specified for the backend" -and $ErrorAction -eq "Stop" }
            Should -Invoke Invoke-External -Exactly 0
        }

        It "will initialise Terraform with the supplied argument" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform init -backend-config='key=tfstate' -backend-config='access_key=123456'" }

            # run the function to call terraform with some arguments for the backend
            Invoke-Terraform -init -Backend "key=tfstate,access_key=123456"

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }

        It "will initialise Terraform with the supplied argument using a ; as the delimiter in the string" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform init -backend-config='key=tfstate' -backend-config='access_key=123456'" }

            # run the function to call terraform with some arguments for the backend
            Invoke-Terraform -init -Backend "key=tfstate;access_key=123456" -Delimiter ";"

            # check that the generated command is correct
            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }

        It "will initialise Terraform using the environment variable for the backend config" {
            # Set the environment variable to use for the backend parameter
            $env:TF_BACKEND = "key=tfstate,access_key=123456"

            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform init -backend-config='key=tfstate' -backend-config='access_key=123456'" }

            Invoke-Terraform -init

            # check that the generated command is correct
            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1

            Remove-Item Env:\TF_BACKEND
        }

        It "will initialise Terraform using an array of backend arguments" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform init -backend-config='key=tfstate' -backend-config='access_key=123456'" }

            Invoke-Terraform -init -Backend @("key=tfstate", "access_key=123456")

            # check that the generated command is correct
            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }

    Context "Workspace" {
        It "will display an error if no arguments are set" {
            Mock `
                -Command Invoke-External `
                -MockWith { }

            Invoke-Terraform -workspace
            Should -Invoke -CommandName Write-Error -Exactly 1
            Should -Invoke Invoke-External -Exactly 0
        }

        It "Will create a new workspace if it does not exist" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform workspace select -or-create=true pester" }

            # Invoke the command under test
            Invoke-Terraform -workspace -Arguments "pester"

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }

    Context "Custom" {
        It "Will run an arbitary terraform command" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform destroy" }

            Invoke-Terraform -Custom -Arguments "destroy"

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }

    Context "Plan" {
        It "will throw an error if a path to the terraform files has not been specified" {
            Mock `
                -Command Invoke-External `
                -MockWith { }

            Invoke-Terraform -plan

            Should -Invoke Write-Error -Exactly 1 -ParameterFilter { $Message -eq "Path to the Terraform files or plan file must be supplied" -and $ErrorAction -eq "Stop" }
            Should -Invoke Invoke-External -Exactly 0
        }

        It "will throw an error if the path to the TF files does not exist" {
            Mock `
                -Command Invoke-External `
                -MockWith { }

            Invoke-Terraform -plan -Path "non/existent/path"

            Should -Invoke Write-Error -Exactly 1 -ParameterFilter { $Message -eq "Specified path does not exist: non/existent/path" -and $ErrorAction -eq "Stop" }
            Should -Invoke Invoke-External -Exactly 0
        }

        It "will run the plan command with the specified arguments" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform plan -input=false -out=tfplan" }

            Invoke-Terraform -plan -Path $testFolder -arguments "-input=false", "-out=tfplan"

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }

        It "will run the plan command with the specified string" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform plan -input=false -out=tfplan" }

            Invoke-Terraform -plan -Path $testFolder -arguments "-input=false,-out=tfplan"

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }

        It "will run the the plan command using an environment variable for the arguments" {
            # Set the environment variable to use for the backend parameter
            $env:TF_BACKEND = "-input=false,-out=tfplan"

            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform plan -input=false -out=tfplan" }

            Invoke-Terraform -plan -Path $testFolder

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1

            Remove-Item Env:\TF_BACKEND
        }
    }

    Context "Apply" {
        It "will throw an error if a path to the plan file has not been specified" {
            Mock `
                -Command Invoke-External `
                -MockWith { }

            Invoke-Terraform -apply

            Should -Invoke Write-Error -Exactly 1 -ParameterFilter { $Message -eq "Path to the Terraform files or plan file must be supplied" -and $ErrorAction -eq "Stop" }
            Should -Invoke Invoke-External -Exactly 0
        }

        It "will throw an error if the specified plan file does not exist" {
            Mock `
                -Command Invoke-External `
                -MockWith { }

            Invoke-Terraform -apply -Path "tfplan"

            Should -Invoke Write-Error -Exactly 1 -ParameterFilter { $Message -eq "Specified path does not exist: tfplan" -and $ErrorAction -eq "Stop" }
            Should -Invoke Invoke-External -Exactly 0
        }

        It "will run the Terraform command to apply the specified plan" {
            # create the plan file to be used
            $planFile = New-Item -ItemType File -Path (Join-Path -Path $testFolder -ChildPath "tfplan")

            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform apply ${planFile}" }

            Invoke-Terraform -apply -Path $planFile

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }

    Context "Format" {
        It "will run commands to check that the TF files are correct" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform fmt -diff -check -recursive" }

            Invoke-Terraform -Format

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }

    Context "Output" {
        It "will output TF state in JSON format" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $commands -eq "terraform output -json" }

            Invoke-Terraform -Output

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }

        It "will output TF state in JSON format, custom depth of 2" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { return "{`"foo`": {`"value`": [[[`"foo`"]]]}}" } `
                -ParameterFilter { $commands -eq "terraform output -json" }

            $json = Invoke-Terraform -Output -JsonDepth 2 -WarningAction:SilentlyContinue

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1

            $json | Should -Be '{"foo":{"value":["System.Object[]"]}}'
        }

        It "will output TF state in JSON format, default depth (50)" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { return "{`"foo`": {`"value`": [[[`"foo`"]]]}}" } `
                -ParameterFilter { $commands -eq "terraform output -json" }

            $json = Invoke-Terraform -Output

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1

            $json | Should -Be '{"foo":{"value":[[["foo"]]]}}'
        }
    }

    Context "Validate" {
        It "will run the commands to perform validation checks" {
            Mock `
                -Command Invoke-External `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { (Compare-Object -ReferenceObject $commands -DifferenceObject @("terraform init -backend=false", "terraform validate")).length -eq 0 }

            Mock `
                -Command Test-Path `
                -Verifiable `
                -MockWith { return $true } `
                -ParameterFilter { $Path -eq ".terraform" }

            Mock `
                -Command Remove-Item `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $Path -eq ".terraform" -and $Recurse.IsPresent -and $Force.IsPresent }

            Mock `
                -Command Test-Path `
                -Verifiable `
                -MockWith { return $true } `
                -ParameterFilter { $Path -eq ".terraform.lock.hcl" }

            Mock `
                -Command Remove-Item `
                -Verifiable `
                -MockWith { } `
                -ParameterFilter { $Path -eq ".terraform.lock.hcl" -and $Recurse.IsPresent -and $Force.IsPresent }

            # Invoke the command under test
            Invoke-Terraform -Validate -Path $testFolder

            Should -InvokeVerifiable
            Should -Invoke Invoke-External -Exactly 1
        }
    }
}
