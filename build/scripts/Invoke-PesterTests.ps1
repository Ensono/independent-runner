
[CmdletBinding()]
param (

    [string]
    # Path to the functions that need to be tests
    $Path,

    [string]
    # Output directory for the results
    $Output = "outputs/tests",

    [switch]
    # State if the unit tests should be run
    $Unittests,

    [switch]
    # State if the coverage report should be run
    $Coverage,

    [string]
    # Unit test format
    $UnitTestFormat = "nunitxml",

    [string]
    # Coverage format
    $CoverageFormat = "JaCoCo",

    [string]
    # Verbsoity of the tests
    $Verbosity = "Normal",

    [string]
    $Tags

)

# Crate configuration object to modify
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

$configuration.filter.Tag = $tags

# Set the verbosity of the tests
$configuration.Output.Verbosity = $verbosity

# Run Pester with the configuration
Invoke-Pester -Configuration $configuration
