
function Invoke-PesterTests() {
    [CmdletBinding()]
param (

    [string]
    # Path to the functions that need to be tests
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
    $verbosity = "Detailed"

)

    # Confirm that the required parameters have been passed to the function
    $result = Confirm-Parameters -List @("path")
    if (!$result) {
        Write-Error -Message "Missing mandatory parameters: path"
        return
    }
        
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

    # Set the verbosity of the tests
    $configuration.Output.Verbosity = $verbosity

    # Run Pester with the configuration
    Invoke-Pester -Configuration $configuration
}
