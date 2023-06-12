function Get-AzureServiceVersions() {

    <#
    
    .SYNOPSIS
    Returns version information for specific services in Azure
    
    .DESCRIPTION
    Some Azure services provide versions that they currently support. This is valuable information
    when performing infrastructure tests. This cmdlet will return the service versions that are supported
    for supported applications.

    The cmdlet is dependant on the Azure PowerShell module to perform the authentication and call the necssary
    commands. This cmdlet is a helper function that takes care of the authentication from the provided
    Service Principal details and then calls the necessary function.

    Service princiapl details can be supplied as enviornment variables, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET and
    AZURE_TENANT_ID or as parameters `client_id`, `client_password` and `tenant_id`.

    At the moment this cmdlet only supports AKS.

    .EXAMPLE
    $env:AZURE_CLIENT_ID = "12345"
    $env:AZURE_CLIENT_PASWORD = "67890"
    $env:AZURE_TENANT_ID = "064c340f-eeae-48d2-badf-6a3b87c9830e"

    Get-AzureServiceVersions -service aks -location westeurope

    #>

    [CmdletBinding()]
    param (

        [string[]]
        # List of services that need versions for
        $services = $env:AZURE_SERVICES,

        [string]
        # Service principal Client ID
        $client_id = $env:AZURE_CLIENT_ID,

        [string]
        # Service principal password
        $client_password = $env:AZURE_CLIENT_SECRET,

        [string]
        # Tenant ID for the Service Principal
        $tenant_id = $env:AZURE_TENANT_ID,

        [string]
        # Location to check for kubernetes versions
        $location
    )

    if ($services.Count -eq 0) {
        Write-Error -Message "Please specify at least one service to check the version of. Combination of [aks]"
        return
    }

    if ($location -eq "") {
        Write-Error -Message "A valid Azure location must be specified"
        return
    }

    if ($client_id -eq "" -or $client_password -eq "" -or $tenant_id -eq "") {
        Write-Error -Message "Service principal information must be provided for authentication, (client_id, client_password, tenant_id)"
    }

    # Create the credential object
    # Convert the password to a secure string
    [SecureString] $secure_pasword = ConvertTo-SecureString -String $client_password -AsPlainText -Force

    # Create the PSCredential Object
    [PSCredential] $creds = New-Object System.Management.Automation.PSCredential ($client_id, $secure_pasword)

    # Connect to Azure
    Connect-AzAccount -ServicePrincipal -Credential $creds -Tenant $tenant_id -WarningAction Ignore | Out-Null

    # Create the hashtable to hold the values that retrieved
    $result = @{}

    switch -Regex ($services) {
        "kubernetes|k8s|aks" {
            $versions = Get-AzAksVersion -Location $location

            $available_versions = @()
            foreach ($version in $versions) {
                $available_versions += $version.OrchestratorVersion
            }

            $result["kubernetes_valid_versions"] = $available_versions
        }
    }


    return $result
}

