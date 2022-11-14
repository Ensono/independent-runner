

function Invoke-Kubectl() {

    <#
    
    .SYNOPSIS
    Is a wrapper around the `kubectl` command for deployment

    .DESCRIPTION
    To help with the invoking the necessary commands for `kubectl` this cmdlet wraps
    the login and the deploy or rollout sub command. This is its primary function, although
    custom commands can be passed to the cmdlet for situations where deploy and rollout do
    not suffice.

    `apply` - deploy one or more manifest files to the kubernetes cluster
    `custom` - perform any `kubectl` command using the arguments 
    `rollout` - performs the rollout command using the specified arguments

    The cmdlet can target Azure and AWS clusters. To specify which one is required the `provider`
    parameter needs to be set. For the identification of the cluster the name needs to be specified
    as well as an identifier. Please see the `identifier` parameter for more information.

    .EXAMPLE
    Invoke-Kubectl -apply -arguments @("manifest1.yml", "manifest2.yml") -provider azure -target myakscluster -identifier myresourcegroup

    Apply the specified manifest files, if they can be located, to the named cluster in azure

    .EXAMPLE
    Invoke-Kubectl custom -arguments @("get", "ns") -provider azure -target myakscluster -identifier myresourcegroup

    Perform a custom command and list all the namespaced in the cluster.

    #>

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
