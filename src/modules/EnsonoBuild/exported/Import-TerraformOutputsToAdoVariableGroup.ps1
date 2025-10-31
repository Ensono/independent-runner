function Import-TerraformOutputsToAdoVariableGroup {

    <#

    .SYNOPSIS
    Processes Terraform outputs and creates/updates Azure DevOps variable groups

    .DESCRIPTION
    This function reads Terraform JSON outputs, processes them into ADO variables (flattening nested objects),
    and creates or updates an Azure DevOps variable group with the processed variables.

    Features:
    - Generic handling of map/dictionary outputs (flattens nested structures)
    - Dry run mode to preview changes without applying them
    - Support for secret/sensitive variables
    - Optional variable name prefixes

    .EXAMPLE
    Import-TerraformOutputsToAdoVariableGroup -organisationName "myorg" -projectName "myproject" -accessToken $token -variableGroupName "terraform-vars" -terraformOutputs "outputs.json"

    Processes Terraform outputs from outputs.json and creates/updates an ADO variable group named "terraform-vars"

    .EXAMPLE
    Import-TerraformOutputsToAdoVariableGroup -organisationName "myorg" -projectName "myproject" -accessToken $token -variableGroupName "terraform-vars" -terraformOutputs "outputs.json" -dryRun

    Previews what changes would be made without actually creating or updating the variable group

    #>

    [CmdletBinding()]
    param (
        # Azure DevOps connection parameters
        [Parameter(Mandatory=$false)]
        [hashtable]$headers = @{"content-type" = "application/json"},

        [Parameter(Mandatory=$true)]
        [string]$organisationName,  # ADO organization name

        [Parameter(Mandatory=$true)]
        [string]$projectName,  # ADO project name

        [Parameter(Mandatory=$false)]
        [string]$apiVersion = "7.1",  # ADO API version

        [Parameter(Mandatory=$true)]
        [string]$accessToken,  # ADO Personal Access Token

        # Variable group configuration
        [Parameter(Mandatory = $true)]
        [string]$variableGroupName,  # Name of the variable group to create/update

        [Parameter(Mandatory = $false)]
        [string]$variableNamePrefix = "",  # Optional prefix for all variable names

        # Terraform outputs
        [Parameter(Mandatory = $true, ParameterSetName = 'Terraform')]
        [string]$terraformOutputs,  # Path to Terraform outputs JSON file

        # Execution options
        [Parameter(Mandatory = $false)]
        [switch]$createOutputVariablesOnly = $false,  # Only create ADO pipeline output variables, skip variable group

        [Parameter(Mandatory = $false)]
        [switch]$dryRun = $false  # Preview changes without applying them
    )


    # =====================
    # Script Setup
    # =====================
    $ErrorActionPreference = "Stop"


# =====================
# Helper Functions
# =====================

Function Get-ADOProject {
    <#
    .SYNOPSIS
    Retrieves Azure DevOps project information

    .DESCRIPTION
    Makes a REST API call to get project details including project ID
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [hashtable]$headers = @{"content-type" = "application/json"},

        [Parameter(Mandatory=$true)]
        [string]$organisationName,

        [Parameter(Mandatory=$true)]
        [string]$projectName,

        [Parameter(Mandatory=$false)]
        [string]$apiVersion = "7.1",

        [Parameter(Mandatory=$true)]
        [string]$accessToken,

        [Parameter(Mandatory=$false)]
        [string]$uriParameters
    )

    $ErrorActionPreference = "Stop"

    $baseURL = ("https://dev.azure.com/{0}" -f $organisationName)

    # Build authentication header
    $parameters = @{
        method = "GET"
        headers = $headers
    }

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($accessToken)"))
    $parameters.headers.Add('Authorization', ("Basic {0}" -f $token))

    # Build query parameters
    if ([string]::IsNullOrEmpty($uriParameters)) {
        $queryParameters = ("api-version={0}" -f $apiVersion)
    } else {
        $queryParameters = ("{0}&api-version={1}" -f $uriParameters, $apiVersion)
    }

    $parameters.Add('uri', [URI]::EscapeUriString(("{0}/_apis/{1}?{2}" -f $baseURL, ("projects/{0}" -f $projectName), $queryParameters)))

    $response = Invoke-RestMethod @parameters | Write-Output

    if ($response.GetType().Name -ne "PSCustomObject") {
        throw ("Expected API response object of '{0}' but got '{1}'" -f "PSCustomObject", $response.GetType().Name)
    }

    return $response
}

Function Get-ADOVariableGroup {
    <#
    .SYNOPSIS
    Retrieves Azure DevOps variable group(s)

    .DESCRIPTION
    Makes a REST API call to get variable group details by name or list all variable groups
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [hashtable]$headers = @{"content-type" = "application/json"},

        [Parameter(Mandatory=$true)]
        [string]$organisationName,

        [Parameter(Mandatory=$true)]
        [string]$projectName,

        [Parameter(Mandatory=$false)]
        [string]$apiVersion = "7.1",

        [Parameter(Mandatory=$true)]
        [string]$accessToken,

        [Parameter(Mandatory=$false)]
        [string]$uriParameters
    )

    $ErrorActionPreference = "Stop"

    $baseURL = ("https://dev.azure.com/{0}/{1}" -f $organisationName, $projectName)

    # Build authentication header
    $parameters = @{
        method = "GET"
        headers = $headers
    }

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($accessToken)"))
    $parameters.headers.Add('Authorization', ("Basic {0}" -f $token))

    # Build query parameters
    if ([string]::IsNullOrEmpty($uriParameters)) {
        $queryParameters = ("api-version={0}" -f $apiVersion)
    } else {
        $queryParameters = ("{0}&api-version={1}" -f $uriParameters, $apiVersion)
    }

    $parameters.Add('uri', [URI]::EscapeUriString(("{0}/_apis/{1}?{2}" -f $baseURL, "distributedtask/variablegroups", $queryParameters)))

    $response = Invoke-RestMethod @parameters | Write-Output

    if ($response.GetType().Name -ne "PSCustomObject") {
        throw ("Expected API response object of '{0}' but got '{1}'" -f "PSCustomObject", $response.GetType().Name)
    }

    return $response
}

Function New-ADOVariableGroup {
    <#
    .SYNOPSIS
    Creates a new Azure DevOps variable group

    .DESCRIPTION
    Makes a REST API call to create a new variable group with the provided configuration
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [hashtable]$headers = @{"content-type" = "application/json"},

        [Parameter(Mandatory=$true)]
        [string]$organisationName,

        [Parameter(Mandatory=$true)]
        [string]$projectName,

        [Parameter(Mandatory=$false)]
        [string]$apiVersion = "7.1",

        [Parameter(Mandatory=$true)]
        [string]$accessToken,

        [Parameter(Mandatory=$false)]
        [string]$uriParameters,

        [Parameter(Mandatory=$true)]
        [hashtable]$payload
    )

    $ErrorActionPreference = "Stop"

    $baseURL = ("https://dev.azure.com/{0}" -f $organisationName)

    # Build authentication header
    $parameters = @{
        method = "POST"
        headers = $headers
    }

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($accessToken)"))
    $parameters.headers.Add('Authorization', ("Basic {0}" -f $token))

    # Build query parameters
    if ([string]::IsNullOrEmpty($uriParameters)) {
        $queryParameters = ("api-version={0}" -f $apiVersion)
    } else {
        $queryParameters = ("{0}&api-version={1}" -f $uriParameters, $apiVersion)
    }

    # Convert payload to JSON
    $body = $payload | ConvertTo-Json -Depth 99

    $parameters.Add('uri', [URI]::EscapeUriString(("{0}/_apis/{1}?{2}" -f $baseURL, "distributedtask/variablegroups", $queryParameters)))
    $parameters.Add('body', ([System.Text.Encoding]::UTF8.GetBytes($body)))

    $response = Invoke-RestMethod @parameters | Write-Output

    if ($response.GetType().Name -ne "PSCustomObject") {
        throw ("Expected API response object of '{0}' but got '{1}'" -f "PSCustomObject", $response.GetType().Name)
    }

    return $response
}

Function Set-ADOVariableGroup {
    <#
    .SYNOPSIS
    Updates an existing Azure DevOps variable group

    .DESCRIPTION
    Makes a REST API call to update a variable group with the provided configuration
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [hashtable]$headers = @{"content-type" = "application/json"},

        [Parameter(Mandatory=$true)]
        [string]$organisationName,

        [Parameter(Mandatory=$true)]
        [string]$projectName,

        [Parameter(Mandatory=$false)]
        [string]$apiVersion = "7.1",

        [Parameter(Mandatory=$true)]
        [string]$accessToken,

        [Parameter(Mandatory=$false)]
        [string]$uriParameters,

        [Parameter(Mandatory=$true)]
        [string]$variableGroupId,

        [Parameter(Mandatory=$true)]
        [hashtable]$payload
    )

    $ErrorActionPreference = "Stop"

    $baseURL = ("https://dev.azure.com/{0}" -f $organisationName)

    # Build authentication header
    $parameters = @{
        method = "PUT"
        headers = $headers
    }

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($accessToken)"))
    $parameters.headers.Add('Authorization', ("Basic {0}" -f $token))

    # Build query parameters
    if ([string]::IsNullOrEmpty($uriParameters)) {
        $queryParameters = ("api-version={0}" -f $apiVersion)
    } else {
        $queryParameters = ("{0}&api-version={1}" -f $uriParameters, $apiVersion)
    }

    # Convert payload to JSON
    $body = $payload | ConvertTo-Json -Depth 99

    $parameters.Add('uri', [URI]::EscapeUriString(("{0}/_apis/{1}?{2}" -f $baseURL, ("distributedtask/variablegroups/{0}" -f $variableGroupId), $queryParameters)))
    $parameters.Add('body', ([System.Text.Encoding]::UTF8.GetBytes($body)))

    $response = Invoke-RestMethod @parameters | Write-Output

    if ($response.GetType().Name -ne "PSCustomObject") {
        throw ("Expected API response object of '{0}' but got '{1}'" -f "PSCustomObject", $response.GetType().Name)
    }

    return $response
}


# =====================================================================================
# MAIN SCRIPT EXECUTION
# =====================================================================================

# =====================
# Process Terraform Outputs
# =====================
if ($PSCmdlet.ParameterSetName -eq "Terraform") {
    Write-Host "\nProcessing Terraform outputs"

    # Display dry run warning if enabled
    if ($dryRun) {
        Write-Host "***** DRY RUN MODE - No changes will be made *****" -ForegroundColor Yellow
    }

    # Validate that the Terraform output file exists
    if (-not (Test-Path -Path $terraformOutputs)) {
        throw ("Missing Terraform json output file:\n{0}" -f $terraformOutputs)
    }

    # Read and parse the Terraform outputs JSON file
    $outputs = Get-Content -Raw -Path $terraformOutputs | Convertfrom-Json
    $outputVariables = New-Object -TypeName PSCustomObject

    # Process each Terraform output
    foreach ($output in $outputs.PSObject.Properties) {
        $variableName = $output.name
        $variableValue = $output.value.value
        Write-Host ("Variable Type: {0}" -f $variableValue.GetType().FullName)

        # Determine if this variable should be marked as secret
        # Default to secret for safety unless explicitly marked as false
        switch ($output.Value.sensitive) {
            false { $isSecret = $false }
            true  { $isSecret = $true }
            default { $isSecret = $true }
        }

        # Check if the value is a complex object (map/dictionary) that needs to be flattened
        # Example: servicebus_topics = { topic1 = "value1", topic2 = "value2" }
        # This will be flattened to: servicebus_topic_topic1, servicebus_topic_topic2
        if ($variableValue -is [PSCustomObject]) {
            # Create a prefix from the output name
            # Converts plural to singular: servicebus_topics -> servicebus_topic_
            $prefix = $variableName -replace 's$', '_'
            if (-not $prefix.EndsWith('_')) {
                $prefix += '_'
            }

            # Flatten each property in the object into individual variables
            foreach ($item in $variableValue.PSObject.Properties) {
                $itemKey = $item.Name
                $itemVarValue = $item.Value
                $itemVarName = "${prefix}${itemKey}".ToLower()

                Write-Host ("Variable Name: {0}" -f $itemVarName)

                # Set as pipeline output variable (for use in subsequent pipeline tasks)
                Write-Host ("##vso[task.setvariable variable=$($itemVarName);isOutput=true]$itemVarValue")

                # Add to the collection that will be stored in the variable group
                $fullVariableName = ("{0}{1}" -f $variableNamePrefix.ToLower(), $itemVarName.ToUpper())
                $outputVariables | Add-Member -NotePropertyName $fullVariableName -NotePropertyValue ([PSCustomObject]@{
                    value    = $itemVarValue
                    isSecret = $isSecret
                })
            }
        }
        else {
            # Handle simple scalar values (strings, numbers, booleans)
            Write-Host ("Variable Name: {0}" -f $variableName)

            # Set as pipeline output variable
            Write-Host ("##vso[task.setvariable variable=$($variableName);isOutput=true]$variableValue")

            # Add to the variable group collection
            $fullVariableName = ("{0}{1}" -f $variableNamePrefix.ToLower(), $variableName.ToUpper())
            $outputVariables | Add-Member -NotePropertyName $fullVariableName -NotePropertyValue ([PSCustomObject]@{
                value    = $variableValue
                isSecret = $isSecret
            })
        }
    }
}

# =====================
# Create or Update Variable Group in Azure DevOps
# =====================
if (-not $createOutputVariablesOnly) {
    $variableGroupName = $variableGroupName.ToLower()
    Write-Host ("\nVariable Group name: {0}\nvariable name prefix: {1}" -f $variableGroupName, $variableNamePrefix)

    # Get the project ID for the variable group references
    $projectId = (Get-ADOProject -organisationName $organisationName -projectName $projectName -accessToken $accessToken).id

    # Check if the variable group already exists
    $response = Get-ADOVariableGroup -organisationName $organisationName -projectName $projectName -uriParameters ("groupName={0}" -f $variableGroupName) -accessToken $accessToken

    # SCENARIO 1: Variable group doesn't exist - CREATE IT
    if ($response.count -eq "0") {
        Write-Host ("ACTION: Create") -ForegroundColor Green

        # Build the variable group payload
        $variableGroupContent = @{
            name        = $variableGroupName
            description = "Variables scoped to: $variableGroupName from Terraform outputs"
            type        = "Vsts"
            variables   = $outputVariables
            variableGroupProjectReferences = @(
                @{
                    name        = $variableGroupName
                    description = "Variables scoped to: $variableGroupName from Terraform outputs"
                    projectReference = @{
                        id = $projectId
                        name = $projectName
                    }
                }
            )
        }

        if ($dryRun) {
            # DRY RUN: Show what would be created without actually creating it
            Write-Host ("\n[DRY RUN] Would create variable group: {0}" -f $variableGroupName) -ForegroundColor Yellow
            Write-Host "Variables to be created:" -ForegroundColor Yellow
            foreach ($var in $outputVariables.PSObject.Properties) {
                $secretIndicator = if ($var.Value.isSecret) { " (secret)" } else { "" }
                Write-Host ("  - {0}{1}" -f $var.Name, $secretIndicator) -ForegroundColor Cyan
            }
        } else {
            # ACTUAL EXECUTION: Create the variable group
            $response = New-ADOVariableGroup -organisationName $organisationName -projectName $projectName -accessToken $accessToken -payload $variableGroupContent
            Write-Host ("Created variable group: {0}" -f $variableGroupName) -ForegroundColor Green
        }
    }
    # SCENARIO 2: Variable group exists - UPDATE IT
    else {
        Write-Host ("ACTION: Update") -ForegroundColor Green

        # Get existing variable group details
        $variableGroup = $response.value[0]
        $variableGroupId = $variableGroup.id
        $variables = $variableGroup.variables

        # Track what's new vs what's being updated (for reporting)
        $newVariables = @()
        $updatedVariables = @()

        # Merge new variables with existing ones
        foreach ($outputVariable in $outputVariables.PSObject.Properties) {
            $key = $outputVariable.Name

            if ($variables.PSObject.Properties.Name -contains $key) {
                # Variable exists - UPDATE it
                $updatedVariables += $key
                $variables.$key = $outputVariable.value
            } else {
                # Variable is new - ADD it
                $newVariables += $key
                $variables | Add-Member -NotePropertyName $key -NotePropertyValue $outputVariable.value
            }
        }

        # Build the updated variable group payload
        $variableGroupContent = @{
            name        = $variableGroupName
            description = "Variables scoped to: $variableGroupName from Terraform outputs"
            type        = "Vsts"
            variables   = $variables
            variableGroupProjectReferences = @(
                @{
                    name        = $variableGroupName
                    description = "Variables scoped to: $variableGroupName from Terraform outputs"
                    projectReference = @{
                        id = $projectId
                        name = $projectName
                    }
                }
            )
        }

        if ($dryRun) {
            # DRY RUN: Show what would be updated without actually updating
            Write-Host ("\n[DRY RUN] Would update variable group: {0} (ID: {1})" -f $variableGroupName, $variableGroupId) -ForegroundColor Yellow

            # Report new variables that would be added
            if ($newVariables.Count -gt 0) {
                Write-Host "`nNew variables to be added:" -ForegroundColor Yellow
                foreach ($varName in $newVariables) {
                    $varValue = $outputVariables.$varName
                    $secretIndicator = if ($varValue.isSecret) { " (secret)" } else { "" }
                    Write-Host ("  + {0}{1}" -f $varName, $secretIndicator) -ForegroundColor Green
                }
            }

            # Report existing variables that would be updated
            if ($updatedVariables.Count -gt 0) {
                Write-Host "`nExisting variables to be updated:" -ForegroundColor Yellow
                foreach ($varName in $updatedVariables) {
                    $varValue = $outputVariables.$varName
                    $secretIndicator = if ($varValue.isSecret) { " (secret)" } else { "" }
                    Write-Host ("  ~ {0}{1}" -f $varName, $secretIndicator) -ForegroundColor Cyan
                }
            }

            # Report if no changes detected
            if ($newVariables.Count -eq 0 -and $updatedVariables.Count -eq 0) {
                Write-Host "`nNo changes detected" -ForegroundColor Gray
            }
        } else {
            # ACTUAL EXECUTION: Update the variable group
            $response = Set-ADOVariableGroup -organisationName $organisationName -projectName $projectName -accessToken $accessToken -variableGroupId $variableGroupId -payload $variableGroupContent
            Write-Host ("Updated variable group: {0}" -f $variableGroupName) -ForegroundColor Green

            # Report summary of changes made
            if ($newVariables.Count -gt 0) {
                Write-Host ("Added {0} new variable(s)" -f $newVariables.Count) -ForegroundColor Green
            }
            if ($updatedVariables.Count -gt 0) {
                Write-Host ("Updated {0} existing variable(s)" -f $updatedVariables.Count) -ForegroundColor Cyan
            }
        }
    }
}

}
