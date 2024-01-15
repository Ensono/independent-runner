

Describe "Invoke-Helm" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Invoke-Helm.ps1

        # Import dependent functions
        . $PSScriptRoot/Invoke-Login.ps1
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        $valueFile = Join-Path -Path $testFolder -ChildPath "chart.yml"
        $chartFile = Join-Path -Path $testFolder -ChildPath "values.yml"
        New-Item -ItemType File -Path $valueFile
        New-Item -ItemType File -Path $chartFile

        # create a session variable to hold the commands that are called
        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }

        Mock -Command Write-Error -Mockwith {}
        # Mock the Find-Command to return a valid path for the tool
        # This is so that the tool does not need to exist on the machine that is running the tests
        Mock -Command Find-Command -MockWith { return "helm" }

        $testclustername = "testcluster"
        $testclusteridentifier = "testclusteridentifier"
        $testrelease = "testrelease"
        $testnamespace = "testnamespace"
    }

    AfterAll {

        Remove-Variable -Name Session -Scope global
    }

    BeforeEach {

        $global:Session.commands.list = @()
    }

    Context "No Parameters" {

        it "will error" {
            $ShouldParams = @{
                Throw = $true
                ExpectedMessage = "Parameter set cannot be resolved using the specified named parameters. One or more parameters issued cannot be used together or an insufficient number of parameters were provided."
                ExceptionType = ([System.Management.Automation.ParameterBindingException])
                # Command to run
                ActualValue = { Invoke-Helm }
            }

            Should @ShouldParams
        }
    }

    Context "Cloud Indepdenent" {

        Context "Repo" {

            BeforeAll {

                Mock -CommandName Invoke-Login `
                    -MockWith { return } `
                    -RemoveParameterValidation tenantId `
                    -ParameterFilter { }
            }

            it "will not log-in to a Cloud Provider and will add a repository" {
                Invoke-Helm -Repo -RepositoryName "MyRepo" -RepositoryUrl "https://foo.bar/"

                $Session.commands.list[0] | Should -BeLike "*helm* repo add MyRepo https://foo.bar/"
                Should -Invoke -CommandName Invoke-Login -Times 0
            }
        }

    }

    Context "Azure" {

        BeforeAll {

            Mock -CommandName Invoke-Login `
                -MockWith { return } `
                -RemoveParameterValidation tenantId `
                -parameterFilter { $provider -eq 'azure' -and $k8s.IsPresent -and $identifier -eq $testclusteridentifier -and $target -eq $testclustername }
        }

        Context "Helm Install" {

            it "will login to Azure and install the relevant chart to the target AKS cluster" {
                Invoke-Helm -provider Azure -target $testclustername -identifier $testclusteridentifier -Install -valuepath values.yml -chartpath chart.yml -releasename $testrelease -namespace $testnamespace

                $Session.commands.list[0] | Should -BeLike "*helm* upgrade $testrelease chart.yml --install --namespace $testnamespace --create-namespace --atomic --values values.yml"
                Should -Invoke -CommandName Invoke-Login -Times 1
            }
        }

        Context "Helm Install with Version" {

            it "will login to Azure and install the relevant chart to the target AKS cluster at a version specified" {
                Invoke-Helm -provider Azure -target $testclustername -identifier $testclusteridentifier -Install -valuepath values.yml -chartpath chart.yml -releasename $testrelease -namespace $testnamespace -chartversion 1.3.2

                $Session.commands.list[0] | Should -BeLike "*helm* upgrade $testrelease chart.yml --install --namespace $testnamespace --create-namespace --atomic --values values.yml --version 1.3.2"
                Should -Invoke -CommandName Invoke-Login -Times 1
            }
        }

        Context "Custom" {

            it "will login to Azure and run a custom command on the target AKS cluster" {
                Invoke-Helm -provider Azure -target $testclustername -identifier $testclusteridentifier -Custom -Arguments "list" -namespace $testnamespace -releasename $testrelease
                Invoke-Helm -provider Azure -target $testclustername -identifier $testclusteridentifier -Custom -Arguments "list"

                $Session.commands.list[0] | Should -BeLike "*helm* list"
                $Session.commands.list[1] | Should -BeLike "*helm* list"
                Should -Invoke -CommandName Invoke-Login -Times 2
            }
        }
    }

    Context "AWS" {

        BeforeAll {

            Mock -CommandName Invoke-Login `
                -MockWith { return } `
                -RemoveParameterValidation tenantId `
                -parameterFilter { $provider -eq 'aws' -and $k8s.IsPresent -and $identifier -eq $testclusteridentifier -and $target -eq $testclustername }
        }

        Context "Helm Install" {

            It "will login to AWS and apply the relevant manifest to the target EKS cluster" {
                Invoke-Helm -provider AWS -target $testclustername -identifier $testclusteridentifier -Install -valuepath values.yml -chartpath chart.yml -releasename $testrelease -namespace $testnamespace

                $Session.commands.list[0] | Should -BeLike  "*helm* upgrade $testrelease chart.yml --install --namespace $testnamespace --create-namespace --atomic --values values.yml"
                Should -Invoke -CommandName Invoke-Login -Times 1
            }
        }

        Context "Custom" {

            It "will login to AWS and run a custom command on the target EKS cluster" {
                Invoke-Helm -provider AWS -target $testclustername -identifier $testclusteridentifier -Custom -Arguments "list" -namespace $testnamespace -releasename $testrelease
                Invoke-Helm -provider AWS -target $testclustername -identifier $testclusteridentifier -Custom -Arguments "list"

                $Session.commands.list[0] | Should -BeLike "*helm* list"
                $Session.commands.list[1] | Should -BeLike "*helm* list"
                Should -Invoke -CommandName Invoke-Login -Times 2
            }
        }
    }
}
