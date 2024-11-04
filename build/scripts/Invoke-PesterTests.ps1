
[CmdletBinding()]
param (

    [string]
    # Path to the functions that need to be tested
    $path,

    [string]
    # Output directory for the results
    $output = "outputs/tests",

    [switch]
    # State if the unit tests should be run
    $unittests,

    [switch]
    # State if the coverage report should be run
    $coverage,

    [string]
    # Unit test format
    $unitTestFormat = "nunitxml",

    [string]
    # Coverage format
    $coverageFormat = "JaCoCo",

    [string]
    # Verbsoity of the tests
    $verbosity = "Normal"

)

# Update Pester
Update-Module -Name Pester -Force

$pesterErrorCodePath = "./test"
$pesterErrorCodeFile = ".PesterErrorCode"
$pesterErrorCodeFilePath = "${pesterErrorCodePath}/${pesterErrorCodeFile}"

if (Test-Path -Path $pesterErrorCodeFilePath -PathType leaf) {
    Write-Debug "Found '${$pesterErrorCodeFilePath}', removing it..."
    Remove-Item -Path $pesterErrorCodeFilePath -Force
}

# Create configuration object to modify
$configuration = New-PesterConfiguration

# Configure the path that the tests will run in
$configuration.Run.Path = $path

# If running unit tests update the configuration
if ($unittests.IsPresent) {
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = $unitTestFormat
    $configuration.TestResult.OutputPath = [IO.Path]::Combine($output, "pester-unittest-results.xml")
}

# add in coverage if it has been specified
if ($coverage.IsPresent) {
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.OutputFormat = $coverageFormat
    $configuration.CodeCoverage.OutputPath = [IO.Path]::Combine($output, "pester-coverage.xml")
}

# Return result object to the pipeline after finishing the test run
$configuration.Run.PassThru = $true

# Set the verbosity of the tests
$configuration.Output.Verbosity = $verbosity

# Run Pester with the configuration
$result = Invoke-Pester -Configuration $configuration

$exitCode = $LASTEXITCODE

if ($IsLinux) {
    $outputRoot = ($output -Split [IO.Path]::DirectorySeparatorChar)[0] | Resolve-Path
    chown -R $env:HOST_UIDGID $outputRoot
}

if ($exitCode -ne 0) {
    Write-Error "ERROR: $($result.FailedCount) Test Failures"

    foreach ($failure in $result.Failed) {
        Write-Error "ERROR: $($failure)`n"
    }

    New-Item `
        -Path $pesterErrorCodeFilePath `
        -Value $exitCode

    exit $exitCode
}
