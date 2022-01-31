

function Invoke-DotNet() {

    [CmdletBinding()]
    param (
        
        [Parameter(
            ParameterSetName="build"
        )]
        [switch]
        # Run .NET Build
        $build,

        [Alias("folder", "project", "workingDirectory")]
        [string]
        # Directory that the build should be performed in
        $path,       

        [Parameter(
            ParameterSetName="coverage"
        )]
        [switch]
        # Run .NET coverage command
        $coverage,

        [Parameter(
            ParameterSetName="coverage"
        )]
        [string]
        # Type of report that should be generated
        $type = "Cobertura",

        [Parameter(
            ParameterSetName="coverage"
        )]
        [Parameter(
            ParameterSetName="tests"
        )]        
        [string]
        # Pattern used to find the files defining the coverage
        $pattern,

        [Parameter(
            ParameterSetName="coverage"
        )]
        [Alias("destination")]
        [string]
        # Target folder for outputs
        $target = "coverage",

        [Parameter(
            ParameterSetName="tests"
        )]
        [switch]
        # Run .NET unit tests
        $tests,

        [Parameter(
            ParameterSetName="custom"
        )]
        [switch]
        # Run an arbitary dotnet command that is not currently defined
        $custom,

        [string]
        # Any additional arguments that should be passed to the command
        $arguments = $env:DOTNET_ARGUMENTS

    )

    # If a working directory has been specified and it exists, change to that dir
    if (![String]::IsNullOrEmpty($path) -and
        (Test-Path -Path $path)) {
        Push-Location -Path $path -StackName "dotnet"
    }

    # Perform the appropriate action based on the Parameter Set Name that
    # has been selected
    switch ($PSCmdlet.ParameterSetName) {
        "build" {
            # Find the path to the command to run
            $dotnet = Find-Command -Name "dotnet"

            # Output the directory that the build is working within
            Write-Information -MessageData ("Working directory: {0}" -f $path) -InformationAction Continue

            # Define the command that needs to be run to perform the build
            $cmd = "{0} build {1}" -f $dotnet, $arguments
        }

        "coverage" {

            # Find the path to the the reportgenerator command
            $tool = Find-Command -Name "reportgenerator"

            # Set the pattern if it has not been defined
            if ([String]::IsNullOrEmpty($pattern)) {
                $pattern = "*.opencover.xml"
            }

            # Find all the files that match the pattern for coverage
            $coverFiles = Find-Projects -Pattern $pattern -Path $path

            # Test to see if any cover files have been found, if not output an error
            # and return
            if ($coverFiles.count -eq 0) {
                Write-Error -Message ("No tests matching the pattern '{0}' can be found" -f $pattern)
                return
            }

            # create a list of the full path to each coverfile
            $list = $coverFiles | ForEach-Object { $_.FullName }

            # Build up the command that should be executed
            $cmd = "{0} -reports:{1} -targetdir:{2} -reporttypes:{3} {4}" -f $tool,
                ($list -join ";"),
                $target,
                $type,
                $arguments
        }

        "custom" {

            # error if no arguments have been set
            if ([string]::IsNullOrEmpty($arguments)) {
                Write-Error -Message "Arguments must be specified when running a custom dotnet command"
                return
            }

            # Find the path to the command to run
            $dotnet = Find-Command -Name "dotnet"

            # Build up the command
            $cmd = "{0} {1}" -f $dotnet, $arguments
        }

        "tests" {

            # Find the path to the command to run
            $dotnet = Find-Command -Name "dotnet"

            # check that a pattern has been specified
            if ([string]::IsNullOrEmpty($pattern)) {
                Write-Error -Message "A pattern must be specfied to find test files"
                return
            }

            # Find all the test files according to the pattern
            $unittests = Find-Projects -Pattern $pattern -Path $path

            if ($unittests.count -eq 0) {
                Write-Error -Message ("No tests matching the pattern '{0}' can be found" -f $pattern)
                return
            }

            # Create a list of commands that need to be run
            $cmd = @()
            foreach ($unittest in $unittests) {
                $cmd += "{0} test {1} {2}" -f $dotnet, $unittest.FullName, $arguments
            }
        }
    }

    # Execute the command
    Invoke-External -Command $cmd

    # Output the exitcode of the command
    $LASTEXITCODE

    # Move back to the original directory
    if ((Get-Location -StackName "dotnet" -ErrorAction SilentlyContinue).length -gt 0) {
        Pop-Location -StackName "dotnet"
    }
}