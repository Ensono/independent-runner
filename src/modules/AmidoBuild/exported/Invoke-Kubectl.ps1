

function Invoke-Kubectl() {

    [CmdletBinding()]
    param (

        [Parameter(
            ParameterSetName="apply"
        )]
        [switch]
        # Run the apply command of Kubectl
        $apply,

        [Parameter(
            ParameterSetName="rollout"
        )]
        [switch]
        # Run the rollout command of Kubectl
        $rollout,
        
        [Parameter(
            ParameterSetName="custom"
        )]
        [switch]
        # Allow a custom command to be run. This allows for the scenario where the function
        # does not support the command that needs to be run
        $custom,          

        [string[]]
        [Alias("properties")]
        # Arguments to pass to the kubectl command
        $arguments
    )

    # Login to cloud
    Invoke-Login

    # Find the kubectl command to use
    $kubectl = Find-Command -Name "kubectl"

    $commands = @()

    # build up and execute the commands that need to be run
    switch ($PSCmdlet.ParameterSetName) {
        "apply" {

            # Check that some arguments have been set
            if ($arguments.Count -eq 0) {
                Write-Error -Message "No manifest files have been specified"
                exit 1
            }

            # Iterate around the arguments that have been specified and deploy each one
            foreach ($manifest in $arguments) {

                # check that the manifest exists
                if (!(Test-Path -Path $manifest)) {
                    Write-Warning -Message ("Unable to find manifest file: {0}" -f $manifest)
                } else {
                    $commands += "{0} apply -f {1}" -f $kubectl, $manifest
                    # Invoke-External -Command $command
                }
            }
        }

        "custom" {

            # Build up the command that is to be run
            $commands = "{0} {1}" -f $kubectl, ($arguments -join " ")
        }


        "rollout" {

            # Build up the full kubectl command
            $commands = "{0} rollout {1}" -f $kubectl, ($arguments -join " ")
            
        }
    }

    if ($commands.count -gt 0) {
        Invoke-External -Command $commands
    }
}