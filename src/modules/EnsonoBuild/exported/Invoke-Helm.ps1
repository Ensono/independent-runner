

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

        [Parameter(
            ParameterSetName="repo"
        )]
        [switch]
        # Allow a repository to be added
        $repo,

        [string[]]
        [Alias("properties")]
        # Arguments to pass to the helm command
        $arguments,

        [string]
        [ValidateSet('azure', 'aws', IgnoreCase)]
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
        # The version of the chart to install
        $chartversion,

        [string]
        # Name of the release
        $releasename,

        [string]
        # Namespace to deploy the release into
        $namespace,

        [string]
        $repositoryName,

        [string]
        $repositoryUrl
    )

    # Define parameter checking vars
    $missing = @()
    $checkParams = @()

    switch ($PSCmdlet.ParameterSetName) {
        "install" {
            # Check that some arguments have been set
            $checkParams = @("provider", "target", "identifier", "namespace", "releasename")
        }

        "repo" {
            $checkParams = @("repositoryName", "repositoryUrl")
        }

        "custom" {
            $checkParams = @("arguments")
        }

    }

    # Ensure that all the required parameters have been set:
    foreach ($parameter in $checkParams) {
        if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
            $missing += $parameter
        }
    }

    # if there are missing parameters throw an error
    if ($missing.length -gt 0) {
        Write-Error -Message ("Required parameters are missing: {0}" -f ($missing -join ", "))
        exit 1
    }

    $login =  {
        Param(
            [string]
            [ValidateSet('azure', 'aws', IgnoreCase)]
            $provider,

            [string]
            $target,

            [string]
            $identifier,

            [bool]
            $k8sauthrequired = $true
        )

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

    # Build up and execute the commands that need to be run
    switch ($PSCmdlet.ParameterSetName) {
        "install" {
            # Invoke-Login
            $login.Invoke($provider, $target, $identifier, $k8sauthrequired)

            $versionString = ''
            if (! [string]::IsNullOrEmpty($chartversion)) {
                $versionString = "--version {0}" -f $chartversion
            }

            # Check that some arguments have been set
            $commands += "{0} upgrade {1} {2} --install --namespace {3} --create-namespace --atomic --values {4} {5}" -f $helm, $releasename, $chartpath, $namespace, $valuepath, $versionString
        }

        "repo" {
            $commands += "{0} repo add {1} {2}" -f $helm, $repositoryName, $repositoryUrl
        }

        "custom" {
            # Invoke-Login
            $login.Invoke($provider, $target, $identifier, $k8sauthrequired)

            # Build up the command that is to be run
            $commands = "{0} {1}" -f $helm, ($arguments -join " ")
        }
    }

    if ($commands.count -gt 0) {
        Invoke-External -Command $commands

        # Stop the task if the LASTEXITCODE is greater than 0
        if ($LASTEXITCODE -gt 0) {
            Stop-Task -ExitCode $LASTEXITCODE
        }
    }
}
