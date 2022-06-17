

function Confirm-Environment() {

    <#
    
    .SYNOPSIS
    Checks that all the environment variables have been configured

    .DESCRIPTION
    Most of the configuration for Stacks pipelines is done using environment variables
    and there can be quite a lot of them. This function uses a file in the repository to determine
    which environment variables are required for different stages and cloud platforms. If any
    environment variables are missing it will exit the task and stop the pipeline. This is
    so that things fail as early as possible.

    The structure of the file describing the envrionment is show below.

    default:
        variables: [{}]
        credentials:
            azure:  [{}]
            aws: [{}]
    
    stages:
        name: <NAME>
        variables: [{}]

    Each of the `[{}]` denotes an array of the following object

        name: ""
        description: ""

    When thisd function runs it merges the default variables, the cloud cerdential variables
    and the stage variables and checks to see that they have been set. If they have not it will
    output a message stating whicch ones have not been set and then fail the task.

    .PARAMETER path
    Path to the file containing the stage environment variables

    .PARAMETER cloud
    Name of the cloud platform being deployed to. Can be set using thew
    `CLOUD_PLATFORM` environment variable. Currently only supports azure and aws.

    .PARAMETER stage
    Name of the stage to check the envirnment for. Can be set using the `STAGE` environnment
    variable.

    This variable is not checked for by this function as it is required by this function. If not
    specified a warning will be displayed stating that no stage has been specified amd will operate
    with the default variables.
    
    #>

    [CmdletBinding()]
    param (

        [string]
        # Path to the file containing the list of environment variables
        # that must be set in the environment
        $path,

        [string]
        # Name of the cloud platform being deployed to. This is so that the credntial
        # environment variables are checked for correctly
        $cloud = $env:CLOUD_PLATFORM,

        [string]
        # Stage being run which determines the variables to be chcked for
        # This stage will be merged with the default check
        # If not specified then only the deafult stage will be checked
        $stage = $env:STAGE
    )

    # Ensure that the $stage and the $cloud are specified
    # This needs to be done when the script gets put into the module

    # Check that the specified path exists
    if (!(Test-Path -Path $path)) {
        Stop-Task -Message ("Specified file does not exist: {0}" -f $path)
        return
    }

    # Check that the command ConvertFrom-Yaml exists
    $exists = Get-Command -Name ConvertFrom-Yaml
    if ([string]::IsNullOrEmpty($exists)) {
        Stop-Task -Message "Please ensure that the Powershell-Yaml module is installed"
    }

    # Create an array to hold the missing environment variables
    $missing = @()

    # Read in the specified file
    $stage_variables = Get-Content -Path $path -Raw
    $stageVars = ConvertFrom-Yaml -Yaml $stage_variables

    # Attempt to get the default variables to check for
    $required = @()
    if ($stageVars.ContainsKey("default")) {

        # get the default variables
        if($stageVars["default"].ContainsKey("variables")) {
            $required += $stageVars["default"]["variables"] | ForEach-Object { $_.Name }
        }

        # get the credentials for the cloud if they have been specified
        if ($stageVars["default"].ContainsKey("credentials") -and
            $stageVars["default"]["credentials"].ContainsKey($cloud)) {
            $required += $stageVars["default"]["credentials"][$cloud] | Where-Object { $_.Required -ne $false } | ForEach-Object { $_.Name }
        }
    }

    # If the stage is not null check that it exists int he stages list and if
    # it does merge with the required list
    if (![String]::IsNullOrEmpty($stage)) {

        # Attempt to get the stage from the file
        $_stage = $stageVars["stages"] | Where-Object { $_.Name -eq $stage }

        if ([String]::IsNullOrEmpty($_stage)) {
            Write-Warning -Message ("Specified stage is unknown: {0}" -f $stage)
        } else {
            $required += $_stage["variables"] | Where-Object { $_.Required -ne $false } | ForEach-Object { $_.Name }
        }

    } else {
        Write-Warning -Message "No stage has been specified, using default environment variables"
    }

    # ensure that required does not contain "empty" items
    $required = $required | Where-Object { $_ -match '\S' }

    # Iterate around all the required variables and ensure that they exist in enviornment
    # If any of them do not then add to the missing array
    foreach ($envname in $required) {

        try {

            # In some cases all of the environment variables have been capitalised, this is to do with TaskCtl.
            # Check for the existence of the variable in UPPER case as well, if it exists create the var with
            # the correct name and then remove the UPPER case value
            $path = [IO.Path]::Combine("env:", $envname)
            $pathUpper = [IO.Path]::Combine("env:", $envname.ToUpper())

            if ((Test-Path -Path $pathUpper) -and !(Test-Path -Path $path)) {
                New-Item -Path $path -Value (Get-ChildItem -Path $pathUpper).Value
                Remove-Item -Path $pathUpper -Confirm:$false
            }

            $dummy = Get-ChildItem -path $path -ErrorAction Stop
        } catch {
            # The variable does not exist
            $missing += $envname
        }
    }

    # If there are missing values provide an error messahe and stop the task
    if ($missing.count -gt 0) {

        # As there is an error the task in Taskctl needs to be stopped
        Stop-Task -Message ("The following environment variables are missing and must be provided: {0}" -f ($missing -join "`n"))

    }
}
