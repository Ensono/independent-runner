function Get-TFVars() {

    <#
    
    .SYNOPSIS
    Creates a Terraform key/variable variable string from environment variables that have a specific prefix

    .DESCRIPTION
    When working with a CI/CD system, such as Azure DevOps, the variables for Terraform are passed in as
    environment variables. However this sometimes needs to be done several times, so this function creates
    a valid TFVars file that can be uploaded as an artifact and used in different stages.
    
    .EXAMPLE

    Set-TFVars | Out-File -FilePath "terraform.tfvars"

    Find all of the environment variables that start with the default prefix (TF_VAR_*) and write them to
    the file "terraform.tfvars"

    #>

    [CmdletBinding()]
    param (

        [string]
        # Prefix to look for in enviornment variables
        $prefix = "TF_VAR_*"
    )

    # configure hashtable of found variables
    $tfvars = @{}

    # Output the values of the enviornment variables
    Get-ChildItem -Path env: | Where-Object name -like $prefix | ForEach-Object {

        # Get th name of the variable, without the prefix
        $name = $_.name -replace $prefix, ""

        # set the value
        $value = $_.value

        if (!($value -is [int]) -and !($value.StartsWith("{")) -and !($value.StartsWith("["))) {
            $value = "`"{0}`"" -f $value
        }

        $tfvars[$name.ToLower()] = $value

    }

    foreach ($item in $tfvars.GetEnumerator()) {
        Write-Output ("{0} = {1}" -f $item.name, $item.value)
    }
}
