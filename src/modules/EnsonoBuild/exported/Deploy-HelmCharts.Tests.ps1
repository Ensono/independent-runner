Describe "Deploy-HelmCharts" {

    $ModulePath

    BeforeAll {

        $InformationPreference = 'Continue'

        # Null any env vars which can be used to alter behaviour of the command
        $env:HELM_CHARTS = $null
        $env:CLOUD_PROVIDER = $null
        $env:CLOUD_PLATFORM = $null

        # Make stubbed module available
        $ModulePath = $env:PSModulePath
        $env:PSModulePath = "$PSScriptRoot/../../../../test/stubs/modules$([IO.Path]::PathSeparator)$env:PSModulePath"

        # Import the function being tested
        . $PSScriptRoot/Deploy-HelmCharts.ps1

        # Import dependencies that the function under test requires
        . $PSScriptRoot/../exported/Invoke-Helm.ps1
        . $PSScriptRoot/../exported/Expand-Template.ps1

        # Mock functions that are called
        Mock -Command Invoke-Helm -MockWith { return }
        Mock -Command Expand-Template -MockWith {
            param($Template, $Target)
            # Ensure the directory exists
            $targetDir = Split-Path -Path $Target -Parent
            if (-not (Test-Path -Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }
            # Write the template to the target
            Set-Content -Path $Target -Value $Template -Force
        }
        Mock -Command Invoke-Expression -MockWith { return }
        Mock -Command Invoke-WebRequest -MockWith { return }
        Mock -Command Get-Content -MockWith {
            param($Path, $Raw)
            # If the path doesn't exist, return empty string to avoid errors
            if (-not (Test-Path -Path $Path)) {
                return ""
            }
            # Otherwise call the real Get-Content
            & (Get-Command Get-Content -CommandType Cmdlet) -Path $Path -Raw:$Raw
        } -ParameterFilter { $Path -like "*values.yaml" -or $Path -like "*Chart.yaml" }
    }

    AfterAll {
        $env:PSModulePath = $ModulePath
    }

    BeforeEach {
        # Create a session object so that the Invoke-Helm function does not
        # execute any commands but the command that would be run can be checked
        $global:Session = @{
            commands = @{
                list = @()
            }
            dryrun = $true
        }

        # Set default cloud provider
        $env:CLOUD_PROVIDER = "azure"
        $env:CLOUD_PLATFORM = "azure"
    }

    AfterEach {
        # Clean up temporary test files
        if (Test-Path -Path "tmp/") {
            Remove-Item -Path "tmp/" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Check mandatory parameters and file validation" {

        BeforeAll {
            Mock -CommandName Write-Error -MockWith {} -Verifiable
            Mock -CommandName Write-Warning -MockWith {} -Verifiable
        }

        It "will use default path if no path is provided" {
            # Create a dummy config file at the default location
            $defaultPath = "deploy/helm/k8s_apps.yaml"
            New-Item -Path (Split-Path $defaultPath -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            Set-Content -Path $defaultPath -Value "charts: []"

            Deploy-HelmCharts -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false

            Should -Invoke -CommandName Write-Error -Times 0

            # Cleanup
            Remove-Item -Path "deploy/" -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "must error if specified file cannot be located" {
            Deploy-HelmCharts -Path "non-existent-file.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster"

            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will create temporary directory if it does not exist" {
            # Create a minimal config file
            $testConfigPath = "test-config.yaml"
            Set-Content -Path $testConfigPath -Value "charts: []"

            Deploy-HelmCharts -Path $testConfigPath -Tempdir "tmp/" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false

            Test-Path -Path "tmp/" | Should -Be $true

            # Cleanup
            Remove-Item -Path $testConfigPath -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Chart filtering and validation" {

        BeforeAll {
            # Create a test configuration file with multiple charts
            $testConfig = @"
charts:
  - name: nginx-ingress
    enabled: true
    location: stable
    repo: https://kubernetes-charts.storage.googleapis.com
    namespace: ingress
  - name: cert-manager
    enabled: false
    location: jetstack
    repo: https://charts.jetstack.io
  - name: azure-only-chart
    enabled: true
    location: azure
    clouds:
      - azure
  - name: aws-only-chart
    enabled: true
    location: aws
    clouds:
      - aws
"@
            Set-Content -Path "test-helm-config.yaml" -Value $testConfig
        }

        AfterAll {
            Remove-Item -Path "test-helm-config.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will skip disabled charts" {
            Mock -CommandName Write-Warning -MockWith {} -Verifiable

            Deploy-HelmCharts -Path "test-helm-config.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false

            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -like "*Chart is not enabled*" } -Times 1
        }

        It "will deploy only specified charts when Names parameter is provided" {
            Mock -CommandName Write-Warning -MockWith {} -Verifiable

            Deploy-HelmCharts -Path "test-helm-config.yaml" -Names @("nginx-ingress") -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false

            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -like "*Skipping chart due to names list*" } -Times 2
        }

        It "will skip charts not matching the cloud platform" {
            Mock -CommandName Write-Warning -MockWith {} -Verifiable
            $env:CLOUD_PLATFORM = "azure"

            Deploy-HelmCharts -Path "test-helm-config.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false

            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -like "*Chart is not for this cloud platform*" } -Times 1
        }
    }

    Context "Helm command execution" {

        BeforeAll {
            # Create a simple test configuration
            $testConfig = @"
charts:
  - name: test-chart
    enabled: true
    location: stable
    repo: https://charts.example.com
    namespace: test-namespace
    version: 1.0.0
    release_name: my-release
"@
            Set-Content -Path "test-helm-simple.yaml" -Value $testConfig
        }

        AfterAll {
            Remove-Item -Path "test-helm-simple.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will add helm repository when repo is specified" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-helm-simple.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*Invoke-Helm -Repo*" } -Times 1
        }

        It "will use release_name when provided" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-helm-simple.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*-releasename my-release*" } -Times 1
        }

        It "will use chart name as release name when release_name is not provided" {
            $testConfig = @"
charts:
  - name: test-chart
    enabled: true
    location: stable
    namespace: default
"@
            Set-Content -Path "test-helm-norelease.yaml" -Value $testConfig
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-helm-norelease.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*-releasename test-chart*" } -Times 1

            Remove-Item -Path "test-helm-norelease.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will include chart version when specified" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-helm-simple.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*-chartversion 1.0.0*" } -Times 1
        }
    }

    Context "Dry run functionality" {

        BeforeAll {
            $testConfig = @"
charts:
  - name: nginx
    enabled: true
    location: stable
    namespace: default
"@
            Set-Content -Path "test-dryrun.yaml" -Value $testConfig
            Mock -CommandName Write-Host -MockWith {}
        }

        AfterAll {
            Remove-Item -Path "test-dryrun.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will output commands when Dryrun is specified" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-dryrun.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*Invoke-Helm*" } -Times 1
        }

        It "will not invoke expressions during dry run" {
            Mock -CommandName Invoke-Expression -MockWith {}

            Deploy-HelmCharts -Path "test-dryrun.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Invoke-Expression -Times 0
        }
    }

    Context "Values template expansion" {

        BeforeAll {
            # Create test values template
            $valuesTemplate = @"
replicaCount: 3
image:
  repository: test-repo
  tag: latest
"@
            Set-Content -Path "test-values.yaml" -Value $valuesTemplate

            $testConfig = @"
charts:
  - name: test-with-values
    enabled: true
    location: stable
    namespace: default
    values_template: test-values.yaml
"@
            Set-Content -Path "test-values-config.yaml" -Value $testConfig
        }

        AfterAll {
            Remove-Item -Path "test-values.yaml" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "test-values-config.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will expand values template when specified" {
            Deploy-HelmCharts -Path "test-values-config.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Expand-Template -Times 2  # Once for config, once for values
        }

        It "will include valuepath in helm command when values template exists" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-values-config.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*-valuepath*" } -Times 1
        }

        It "will warn if values template file cannot be found" {
            $testConfig = @"
charts:
  - name: test-missing-values
    enabled: true
    location: stable
    namespace: default
    values_template: missing-file.yaml
"@
            Set-Content -Path "test-missing-values.yaml" -Value $testConfig
            Mock -CommandName Write-Warning -MockWith {} -Verifiable

            Deploy-HelmCharts -Path "test-missing-values.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false

            Should -Invoke -CommandName Write-Warning -ParameterFilter { $Message -like "*Values template file cannnot be found*" } -Times 1

            Remove-Item -Path "test-missing-values.yaml" -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Raw YAML wrapping" {

        BeforeAll {
            $testConfig = @"
charts:
  - name: raw-manifest
    enabled: true
    location: https://example.com/manifest.yaml
    wrap_raw_yaml: true
    namespace: default
"@
            Set-Content -Path "test-raw-yaml.yaml" -Value $testConfig
            Mock -CommandName Add-Content -MockWith {}
        }

        AfterAll {
            Remove-Item -Path "test-raw-yaml.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will download and wrap raw YAML when wrap_raw_yaml is true" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-raw-yaml.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Invoke-WebRequest -Times 1
            Should -Invoke -CommandName Add-Content -ParameterFilter { $Path -like "*Chart.yaml" } -Times 1
        }

        It "will use default version 0.0.1 when no versioning_regex is provided" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-raw-yaml.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Add-Content -ParameterFilter { $Value -like "*version: 0.0.1*" } -Times 1
        }

        It "will extract version from URL when versioning_regex is provided" {
            $testConfigVersioned = @"
charts:
  - name: versioned-manifest
    enabled: true
    location: https://example.com/manifests/v1.2.3/manifest.yaml
    wrap_raw_yaml: true
    versioning_regex: '/v(\d+\.\d+\.\d+)/'
    namespace: default
"@
            Set-Content -Path "test-versioned-yaml.yaml" -Value $testConfigVersioned
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-versioned-yaml.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Add-Content -ParameterFilter { $Value -like "*version: 1.2.3*" } -Times 1

            Remove-Item -Path "test-versioned-yaml.yaml" -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Rollout status checks" {

        BeforeAll {
            $testConfig = @"
charts:
  - name: chart-with-rollout
    enabled: true
    location: stable
    namespace: default
    rollout_checks:
      - name: deployment/test-deployment
        timeout: 120s
        namespace: default
"@
            Set-Content -Path "test-rollout.yaml" -Value $testConfig
        }

        AfterAll {
            Remove-Item -Path "test-rollout.yaml" -Force -ErrorAction SilentlyContinue
        }

        It "will execute rollout status checks when specified" {
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-rollout.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*kubectl rollout status*" } -Times 1
        }

        It "will use default timeout if not specified in rollout check" {
            $testConfig = @"
charts:
  - name: chart-default-timeout
    enabled: true
    location: stable
    namespace: default
    rollout_checks:
      - name: deployment/test
"@
            Set-Content -Path "test-rollout-default.yaml" -Value $testConfig
            Mock -CommandName Write-Host -MockWith {}

            Deploy-HelmCharts -Path "test-rollout-default.yaml" -Provider "azure" -Identifier "test-rg" -ClusterName "test-cluster" -K8sAuthRequired $false -Dryrun

            Should -Invoke -CommandName Write-Host -ParameterFilter { $Object -like "*--timeout 60s*" } -Times 1

            Remove-Item -Path "test-rollout-default.yaml" -Force -ErrorAction SilentlyContinue
        }
    }
}
