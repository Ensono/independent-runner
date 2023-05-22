

Describe "Invoke-Helm" {

    BeforeAll {
        . $PSScriptRoot/Invoke-Helm.ps1
        . $PSScriptRoot/Invoke-Login.ps1
        . $PSScriptRoot/../command/Find-Command.ps1
        . $PSScriptRoot/../command/Invoke-External.ps1

        # Create the testFolder
        $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        $valueFile = Join-Path -Path $testFolder -ChildPath "chart.yml"
        $chartFile = Join-Path -Path $testFolder -ChildPath "values.yml"
        New-Item -ItemType File -Path $valueFile
        New-Item -ItemType File -Path $chartFile


        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }

        Mock -CommandName Write-Error -Mockwith {}
        # Mock the Find-Command to return a valid path for the tool
        # This is so that the tool does not need to exist on the machine that is running the tests
        Mock -Command Find-Command -MockWith { return "helm" }

        $testclustername = "testcluster"
        $testclusteridentifier = "testclusteridentifier"

    }

    AfterAll {

        Remove-Variable -Name Session -Scope global
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

    # Azure

    Context "Helm Install" {
        BeforeEach {
            Mock -CommandName Invoke-Login -MockWith { return } -RemoveParameterValidation tenantId -parameterFilter { $provider -eq 'azure' -and $k8s.IsPresent -and $identifier -eq $testclusteridentifier -and $target -eq $testclustername }
            Invoke-Helm -provider Azure -target $testclustername -identifier $testclusteridentifier -Install -valuepath values.yml -chartpath chart.yml
        }

        It "will login to Azure and install the relevant chart to the target AKS cluster" {
            $Session.commands.list[0] | Should -BeLike "*helm* upgrade --install --atomic --values values.yml chart.yml"
            Should -Invoke -CommandName Invoke-Login -Times 1
        }
    }

    Context "Azure Custom" {

        BeforeEach {
            Mock -CommandName Invoke-Login -MockWith { return } -RemoveParameterValidation tenantId -parameterFilter { $provider -eq 'azure' -and $k8s.IsPresent -and $identifier -eq $testclusteridentifier -and $target -eq $testclustername }
            Invoke-Helm -provider Azure -target $testclustername -identifier $testclusteridentifier -Custom -Arguments "list"
        }
        It "will login to Azure and run a custom command on the target AKS cluster" {

            $Session.commands.list[1] | Should -BeLike "*helm* list"
            Should -Invoke -CommandName Invoke-Login -Times 1
        }
    }

    # AWS

    Context "AWS Install" {
        BeforeEach {
            Mock -CommandName Invoke-Login -MockWith { return } -RemoveParameterValidation tenantId -parameterFilter { $provider -eq 'AWS' -and $k8s.IsPresent -and $identifier -eq $testclusteridentifier -and $target -eq $testclustername }
            Invoke-Helm -provider AWS -target $testclustername -identifier $testclusteridentifier -Install -valuepath values.yml -chartpath chart.yml
        }

        It "will login to AWS and apply the relevant manifest to the target AKS cluster" {
            $Session.commands.list[0] | Should -BeLike "*helm* upgrade --install --atomic --values values.yml chart.yml"
            Should -Invoke -CommandName Invoke-Login -Times 1
        }
    }

    Context "AWS Custom" {

        BeforeEach {
            Mock -CommandName Invoke-Login -MockWith { return } -RemoveParameterValidation tenantId -parameterFilter { $provider -eq 'AWS' -and $k8s.IsPresent -and $identifier -eq $testclusteridentifier -and $target -eq $testclustername }
            Invoke-Helm -provider AWS -target $testclustername -identifier $testclusteridentifier -Custom -Arguments "deploy"
        }
        It "will login to AWS and run a custom command on the target AKS cluster" {

            $Session.commands.list[1] | Should -BeLike "*helm* list"
            Should -Invoke -CommandName Invoke-Login -Times 1
        }
    }
}
