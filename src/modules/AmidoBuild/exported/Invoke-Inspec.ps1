
function Invoke-Inspec() {

    [CmdletBinding()]
    param (

        [string]
        # Path to the inspec test files
        $path = $env:TESTS_PATH,

        [Parameter(
            ParameterSetName = "init"
        )]
        [switch]
        # Initialise Inspec
        $init,

        [Parameter(
            ParameterSetName = "exec"
        )]
        [switch]
        $execute,

        [Parameter(
            ParameterSetName = "exec"
        )]
        [string]
        $cloud = $env:CLOUD_PLATFORM,

        [Parameter(
            ParameterSetName = "exec"
        )]
        [string]
        # Name of the report file
        $reportFileName = $env:REPORT_FILENAME,

        [Parameter(
            ParameterSetName = "vendor"
        )]
        [switch]
        $vendor,        

        [Alias("args")]
        [string[]]
        # Arguents to be passed to the command
        $arguments = $env:INSPEC_ARGS,

        [string]
        # Output path for test report
        $output = $env:INSPEC_OUTPUT_PATH

    )

    # Setflag to state if the directory has been changed
    $changedDir = $false

    # Define the inspec command that should be executed
    $command = ""

    # Set a list of parameters that are expected
    $list = @()

    if ([string]::IsNullOrEmpty($path)) {
        Stop-Task -Message "Path to the Inspec test files must be specified"
    }

    if (!(Test-Path -Path $path)) {
        Stop-Task -Message ("Specfied path for Inspec files does not exist: {0}" -f $path)
    }

    # Determine the directory of the path and change to it
    $dir = $path
    if (!((Get-Item -Path $path) -is [System.IO.DirectoryInfo])) {
        $dir = Split-Path -Path $path -Parent
    }

    Push-Location -Path $dir
    $changedDir = $true

    # Confirm the required parameters for different switches
    # Ensure that a cloud platform has been supplied if running exec
    if (@("exec").Contains($PSCmdlet.ParameterSetName)) {
        # add to the list of parameters that need to be specified
        $list += "cloud"
    }

    $result = Confirm-Parameters -List $list
    if (!$result) {
        return
    }

    # Find the Inspec command to run
    $inspec = Find-Command -Name "inspec"

    Write-Information -MessageData ("Working directory: {0}" -f (Get-Location))

    # Select the operation to run based on the switch
    switch ($PSCmdlet.ParameterSetName) {

        # Initalise Inspec
        "init" {
            $command = "{0} init" -f $inspec
        }

        # Execute inspec
        "exec" {

            # Create an array to hold each part of the overall command
            # This is because the order of the commands is important, e.g. any inputs that have been specfied
            # in the arguments need to be put at the end of the command
            # The array will be joined together to make the command

            # Add the necessary initial parts
            $cmd_parts = @($inspec, "exec", ".")

            # Add in the cloud
            $cmd_parts += "-t {0}://" -f $cloud

            # Ensure that the results are show on the console
            $cmd_parts += "--reporter cli"

            # If an output path has been passed add it to the array
            if (![String]::IsNullOrEmpty($output)) {

                # if hte output does not exist create it
                if (!(Test-Path -Path $output)) {
                    New-Item -ItemType Directory -Path $output
                }

                # Check that a reportFilename has been specified, if not generate the filename
                if ([String]::IsNullOrEmpty($reportFileName)) {
                    $reportFileName = "inspec_tests_{0}_{1}.xml" -f $cloud, (Split-Path -Path $path -Leaf)
                }

                $cmd_parts += "junit2:{0}" -f ([IO.Path]::Combine($output, $reportFileName))
            }

            # Extract any inputs that have been found in the arguments and ensure they are places
            # at the end of the command
            # This is because inpsec interprets the --input argument as taking everyting after it

            # Define the pattern to use to find the inputs in the argumnents string
            $pattern =  "(\s*?--input.*?(?= --))"

            # Get a string of the arguments to work with
            $_args = $arguments -join " "

            # Extract the inputs from the string
            $inputs = ""
            if ($_args -match $pattern) {
                $inputs = $matches[1].Trim()
            }

            # Replace the inputs in the $_args with null so that they can be place int he correct place
            $a = ($_args -replace $pattern, "").Trim()

            # Add to the results to the $cmd_parts
            if (![String]::IsNullOrEmpty($a)) {
                $cmd_parts += $a
            }

            if (![String]::IsNullOrEmpty($inputs)) {
                $cmd_parts += $inputs
            }

            $command = $cmd_parts -join " "

            # if an output path has been specified generate a report of the tests

        }

        # Vendor all of the libraries and providers that need to be installed
        "vendor" {
            $command = "{0} vendor . {1}" -f $inspec, ($arguments -join (" "))
        }
    }

    # Run the command that has been built up
    if (![string]::IsNullOrEmpty($command)) {
        Invoke-External -Command $command
    }

    # Change back to the original dirrectory if changed at the begining
    if ($changedDir) {
        Pop-Location -ErrorAction SilentlyContinue
    }
}