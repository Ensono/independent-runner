
function Invoke-PesterTests() {
    <#
        .SYNOPSIS
        TBC

        .DESCRIPTION
        TBC

        .EXAMPLE
        TBC
    #>

    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory=$true
        )]
        [ValidateScript(
            {
                Test-Path -Path $_ 
            },
            ErrorMessage = "Specified path does not exist: {0}."
        )]
        [string]
        # Path to the code to be tested
        $path,

        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet(
            "None",
            "Normal",
            "Detailed",
            "Diagnostic"
        )]
        [string]
        # Verbsoity of the tests
        $outputVerbosity = "Normal",

        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet(
            "None",
            "FirstLine",
            "Filtered",
            "Full"
        )]
        [string]
        # Stack trace verbsoity of the tests
        $outputStackTraceVerbosity = "Filtered",

        [string]
        # Output directory for the results
        $output = "outputs/tests",
        
        [switch]
        # State if the test result file should be produced
        $testResult,

        [string]
        # Test result file format
        $testResultFormat = "nunitxml",

        [string]
        # Test result file name suffix to append
        $testResultFilenameSuffix,

        [switch]
        # State if the code coverage report should be produced
        $codeCoverage,

        [string]
        # Coverage format
        $codeCoverageFormat = "JaCoCo",
        
        [string[]]
        # Filter tags to include
        $filterIncludeTags,

        [string[]]
        # Filter tags to exclude
        $filterExludeTags
    )

    # Create configuration object to modify
    # https://pester.dev/docs/commands/New-PesterConfiguration
    $configuration = New-PesterConfiguration

    # Configure the path that the tests will run in
    $configuration.Run.Path = $path
    
    # Configure how to report test failures
    $configuration.Run.Throw = $true


    # If running unit tests update the configuration
    if ($testResult.IsPresent) {
        if ([string]::IsNullOrEmpty($testResultFilenameSuffix)) {
            $testResultFilename = "pester-results.xml"
        } else {
            $testResultFilename = ("pester-results-{0}.xml" -f $testResultFilenameSuffix)
        }
        
        $configuration.TestResult.Enabled = $true
        $configuration.TestResult.OutputFormat = $testResultFormat
        $configuration.TestResult.OutputPath = [IO.Path]::Combine($output, $testResultFilename)
    }

    # Add in coverage if it has been specified
    if ($codeCoverage.IsPresent) {
        $configuration.CodeCoverage.Enabled = $true
        $configuration.CodeCoverage.OutputFormat = $codeCoverageFormat
        $configuration.CodeCoverage.OutputPath = [IO.Path]::Combine($output, "pester-coverage.xml")
    }

    # # Add filter tags if they have been specified
    # if ($filterTag.IsPresent) {
    #     if ($filterIncludeTags.Length -ne 0) {
    #         $configuration.Filter.Tag = $filterIncludeTags
    #     }

    #     if ($filterExludeTags.Length -ne 0) {
    #         $configuration.Filter.ExcludeTag = $filterExludeTags
    #     }
    # }

    # Set filter tags if they have been specified
    $configuration.Filter.Tag = $filterIncludeTags
    $configuration.Filter.ExcludeTag = $filterExludeTags
    
    # Set the verbosity of the tests
    $configuration.Output.Verbosity = $outputVerbosity
    $configuration.Output.StackTraceVerbosity = $outputStackTraceVerbosity

    # Run Pester with the configuration
    Invoke-Pester -Configuration $configuration
}