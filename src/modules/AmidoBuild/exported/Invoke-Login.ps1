
function Invoke-Login() {

    [CmdletBinding()]
    param (

        [switch]
        # Specify if Kubernetes credentials should be retrieved
        $k8s,

        [string]
        # Name of the cluster to get credentials for
        $k8sName,

        [Parameter(
            ParameterSetName="azure"
        )]
        [string]
        # If logging into AKS then set the resource group that the cluster is in
        $resourceGroup,

        [Parameter(
            ParameterSetName="azure"
        )]
        [switch]
        # Cloud being connected to
        $azure,

        [Parameter(
            ParameterSetName="azure"
        )]
        [string]
        # Tenant ID for the account
        $tenantId = $env:ARM_TENANT_ID,

        [Parameter(
            ParameterSetName="azure"
        )]
        [string]
        # ID of the subscription to use for resources
        $subscriptionId = $env:ARM_SUBSCRIPTION_ID,

        [Parameter(
            ParameterSetName="azure"
        )]
        [Alias("clientId")]
        [string]
        # Username to use to access the specifiec cloud
        # For Azure this will the value for azurerm_client_id
        $username = $env:ARM_CLIENT_ID,

        [Parameter(
            ParameterSetName="azure"
        )]
        [Alias("clientSecret")]
        [string]
        # Password to be used - this is not leveraged as a SecureString, so it can be sourced from an environment variable
        # For Azure this will be the value for azurerm_client_secret
        $password = $env:ARM_CLIENT_SECRET,

        [Parameter(
            ParameterSetName="aws"
        )]
        [switch]
        # Cloud being connected to
        $aws,

        [Parameter(
            ParameterSetName="aws"
        )]
        [string]
        # Cloud being connected to
        $key_id = $env:AWS_ACCESS_KEY_ID,

        [Parameter(
            ParameterSetName="aws"
        )]
        [string]
        # Password to be used
        # For Azure this will be the value for azurerm_client_id
        # For AWS this will be the value for AWS_SECRET_ACCESS_KEY
        $key_secret = $env:AWS_SECRET_ACCESS_KEY,

        [Parameter(
            ParameterSetName="aws"
        )]
        [string]
        # If logging into EKS then set the resource group that the cluster is in
        $region = $env:AWS_DEFAULT_REGION

    )

    $missing = @()

    # if running in dry run mode do not attempt to login
    if (Get-Variable -Name Session -Scope global -ErrorAction SilentlyContinue) {
        if ($global:Session.dryrun) {
            return
        }
    }

    # Perform the necessary login based on the specified cloud
    switch ($PSCmdlet.ParameterSetName) {
        "azure" {

            # Ensure that all the required parameters have been set
            foreach ($parameter in @("tenantId", "subscriptionId", "username", "password")) {

                # check each parameter to see if it has been set
                if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
                    $missing += $parameter
                }
            }

            # if there are missing parameters throw an error
            if ($missing.length -gt 0) {
                Write-Error -Message ("Required parameters are missing: {0}" -f ($missing -join ", "))
            } else {

                # Connect to Azure
                Connect-Azure -clientId $username -secret $password -subscription $subscriptionId -tenantId $tenantId
                return $LASTEXITCODE
                # Set the subscription that should be used
                # Set-AzContext -Subscription $subscriptionId

                # Import AKS credentials if specified
                if ($k8s.IsPresent) {
                    
                    foreach ($parameter in @("k8sname", "resourceGroup")) {

                        # check each parameter to see if it has been set
                        if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
                            $missing += $parameter
                        }
                    }
        
                    # if there are missing parameters throw an error
                    if ($missing.length -gt 0) {
                        Write-Error -Message ("Required K8S parameters are missing: {0}" -f ($missing -join ", "))
                    } else {
                    
                    Import-AzAksCredential -ResourceGroupName $resourceGroup -Name $k8sName
                    }
                }
            }
        }

        "aws" {

            # Ensure that all the required parameters have been set
            foreach ($parameter in @("region", "key_id", "key_secret")) {

                # check each parameter to see if it has been set
                if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
                    $missing += $parameter
                }
            }

            # if there are missing parameters throw an error
            if ($missing.length -gt 0) {
                Write-Error -Message ("Required parameters are missing: {0}" -f ($missing -join ", "))
            } else {
                Write-Warning -Message ("AWS not yet implemented, would be checking for AWS env vars for AWS_ACCESS_KEY_ID={0} , and AWS_SECRET_ACCESS_KEY (not shown) and AWS_DEFAULT_REGION={1}" -f $key_id, $region)

                # Import EKS credentials if specified
                if ($k8s.IsPresent) {
                    
                    foreach ($parameter in @("k8sname", "region")) {

                        # check each parameter to see if it has been set
                        if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
                            $missing += $parameter
                        }
                    }
        
                    # if there are missing parameters throw an error
                    if ($missing.length -gt 0) {
                        Write-Error -Message ("Required K8S parameters are missing: {0}" -f ($missing -join ", "))
                    } else {
                        Write-Warning -Message ("EKS not yet implemented, would be running something like: aws eks update-kubeconfig --name {0} —region {1}" -f $k8sName, $region)
                    }
                }
            }
            Write-Error -Message ("Not authenticated")
        }

        default {

            if ([string]::IsNullOrEmpty($cloud)) {
                Write-Error -Message "A cloud platform must be specified"
            } else {
                Write-Error -Message ("Specified cloud is not supported: {0}" -f $cloud)
            }
            
            return
        }
    }
}
