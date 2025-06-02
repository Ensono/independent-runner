function Set-TFVars() {

    <#
    
    .SYNOPSIS
    Simple wrapper cmdlet for Get-TFVars to maintain backwards compatibility
    
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

    Write-Warning -Message "Set-TFVars is deprecated, please use Get-TFVars instead. Set-TFVars will be removed in the next minor version."

    Get-TFVars -prefix $prefix
}
