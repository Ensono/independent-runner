Describe "Update-InfluxDashboard" {

    BeforeAll {

        # Import function under test
        . $PSScriptRoot/Update-InfluxDashboard.ps1
        
        # Import dependencies
        . $PSScriptRoot/../utils/Confirm-Parameters.ps1
        . $PSScriptRoot/../utils/Confirm-IsWebAddress.ps1
        . $PSScriptRoot/../utils/Confirm-SemVer.ps1
        . $PSScriptRoot/../utils/Confirm-CSL.ps1
        
        # Mocks
        Mock -CommandName Invoke-RestMethod -MockWith {}
        Mock -CommandName Write-Error -MockWith {}
        Mock -CommandName Confirm-CSL -MockWith { $true }
        Mock -CommandName Confirm-SemVer -MockWith { $true }
        Mock -CommandName Confirm-IsWebAddress -MockWith { $true }  
        Mock -CommandName Write-Information -MockWith {}

    }

    Context "Parameterised Configuration" {

        It "if publishRelease parameter nor env var has been set" {

            Update-InfluxDashboard

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "if publishRelease parameter has been set to false" {

            Update-InfluxDashboard -publishRelease $false

            Should -Invoke -CommandName Write-Information -Times 1
        }

        It "will raise an error as not all the required params have been set" {

            Update-InfluxDashboard -publishRelease $true

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will update the Deployment Dashboard" {

            Update-InfluxDashboard -measurement xxxx -tags xxxx -version xxxx -influx_server xxxx -influx_token xxxx -influx_org xxxx -influx_bucket xxxx -publishRelease $true

            Should -Invoke -CommandName Invoke-RestMethod -Times 1
        }
    }

    Context "Environment Variable Configuration" {

        BeforeEach {

            $env:PUBLISH_RELEASE = 'true'
        }

        AfterEach {

            $env:PUBLISH_RELEASE = $null
        }

        It "will raise an error as not all the required params have been set" {

            Update-InfluxDashboard

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will update the Deployment Dashboard" {

            Update-InfluxDashboard -measurement xxxx -tags xxxx -version xxxx -influx_server xxxx -influx_token xxxx -influx_org xxxx -influx_bucket xxxx

            Should -Invoke -CommandName Invoke-RestMethod -Times 1
        }
    }
}
