
function Invoke-Login() {

    [CmdletBinding()]
    param (

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

        [Alias("clientId")]
        [string]
        # Username to use to access the specifiec cloud
        # For Azure this will the client_secret
        $username = $env:AMIDOBUILD_LOGIN_USERNAME,

        [Alias("clientSecret")]
        [SecureString]
        # Password to be used
        # For Azure this will be the client_id
        $password = $env:AMIDOBUILD_LOGIN_PASSWORD,

        [switch]
        # Specify if AKS credentials should be retrieved
        $aks,

        [string]
        # If logging into AKS then set the group that the cluster is in
        $k8sGroup,

        [string]
        # Name of the cluster to get cerdentials for
        $k8sName

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

                # Set the subscription that should be used
                # Set-AzContext -Subscription $subscriptionId

                # Import AKS credentials if specified
                if ($aks.IsPresent) {
                    Import-AzAksCredential -ResourceGroupName $k8sGroup -Name $k8sName
                }
            }
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