

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
        $arguments,

        [string]
        [ValidateSet('azure','aws',IgnoreCase)]
        # Cloud Provider
        $provider,

        [string]
        # Target K8S cluster resource name in Cloud Provider
        $target,

        [string]
        # Unique identifier for K8S in a given Cloud Provider: region for AWS, resourceGroup for Azure, project for GKE
        $identifier

    )
    $missing = @()
    # Ensure that all the required parameters have been set
    foreach ($parameter in @("provider", "target", "identifier")) {

        # check each parameter to see if it has been set
        if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
            $missing += $parameter
        }
    }

    # if there are missing parameters throw an error
    if ($missing.length -gt 0) {
        Write-Error -Message ("Required parameters are missing: {0}" -f ($missing -join ", "))
    } else {

        switch ($provider) {
            "Azure" {
                Invoke-Login -Azure -k8s -k8sName $target -resourceGroup $identifier
            }
            "AWS" {
                Invoke-Login  -AWS -k8s -k8sName $target -region $identifier
            }
            default {
                Write-Error -Message ("Cloud provider not supported for login: {0}" -f $provider)
            }
        } 

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
}
