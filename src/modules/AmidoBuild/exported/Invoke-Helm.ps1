

function Invoke-Helm() {

    <#

    .SYNOPSIS
    Is a wrapper around the `helm` command for deployment

    .DESCRIPTION
    To help with the invoking the necessary commands for `helm` this cmdlet wraps
    the login and the deploy or rollout sub command. This is its primary function, although
    custom commands can be passed to the cmdlet for situations where deploy and rollout do
    not suffice.

    `custom` - perform any `helm` command using the arguments
    `install` - performs a 'helm upgrade --install command

    The cmdlet can target Azure and AWS clusters. To specify which one is required the `provider`
    parameter needs to be set. For the identification of the cluster the name needs to be specified
    as well as an identifier. Please see the `identifier` parameter for more information.

    .EXAMPLE
    ,

    .EXAMPLE
    .
    #>

    [CmdletBinding()]
    param (

        [Parameter(
            ParameterSetName="install"
        )]
        [switch]
        # Run the install command of helm
        $install,

        [Parameter(
            ParameterSetName="custom"
        )]
        [switch]
        # Allow a custom command to be run. This allows for the scenario where the function
        # does not support the command that needs to be run
        $custom,

        [string[]]
        [Alias("properties")]
        # Arguments to pass to the helm command
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
        $identifier,

        [bool]
        # Whether to authenticate to K8S, defaults to true
        $k8sauthrequired = $true,

        [string]
        # Path to a values file
        $valuepath,

        [string]
        # Path to a chart resource
        $chartpath,

        [string]
        $releasename
        # Name of the release

    )

    # Define parameter checking vars
    $missing = @()


      # Ensure that all the required parameters have been set:
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
                Invoke-Login -Azure -k8s:$k8sauthrequired -k8sName $target -resourceGroup $identifier
            }
            "AWS" {
                Invoke-Login  -AWS -k8s:$k8sauthrequired -k8sName $target -region $identifier
            }
            default {
                Write-Error -Message ("Cloud provider not supported for login: {0}" -f $provider)
            }
          }
        }
        # Find the helm binary
        $helm = Find-Command -Name "helm"

        $commands = @()

        # build up and execute the commands that need to be run
        switch ($PSCmdlet.ParameterSetName) {
            "install" {
                # Check that some arguments have been set

                $commands += "{0} upgrade {1} {2} --install --create-namespace --atomic --values {3}" -f $helm, $releasename, $chartpath, $valuepath
                    }

            "custom" {
                # Build up the command that is to be run
                $commands = "{0} {1}" -f $helm, ($arguments -join " ")
            }

        }

        if ($commands.count -gt 0) {
            Invoke-External -Command $commands
        }
  }

