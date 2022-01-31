
<#

.SYNOPSIS
Expand variables in a template file and output to the specified destination

.DESCRIPTION
This function mimics the `envsubst` command in Linux and expands any variable in a template file
and outputs it to a file or stdout

PowerShell deals with environment variables slightly differently in that they are prefixed, e.g. env:NAME
So that variables such as ${NAME} can be expanded the env vars need to be converted to scoped level variables
Ths function will get all enviornment variables and make then local variables for the expansion to use.

If no target is specified then the template is output to stdout

#>
function Expand-Template() {

    [CmdletBinding()]
    param (
        [string]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="content",
            ValueFromPipeline=$true
        )]
        # Content of the template to use
        $template,

        [string]
        [Parameter(
            Mandatory=$true,
            ParameterSetName="path"
        )]
        [Alias("i")]
        # Path to the file to use as the template
        $path,

        [Alias("o", "variables")]
        [string]
        # Target path for the output file
        $target,

        [Alias("a")]
        [hashtable]
        # Specify a list of additional values that should be added
        $additional = @{},

        [Alias("s")]
        [switch]
        # State if information about the transformation should be output
        $show,

        [switch]
        # State if the rendered template should be set on the pipeline
        $pipeline
    )
    
    # check that the path exists if the path parametersetname is being used
    if ($PSCmdlet.ParameterSetName -eq "path") {
        if (!(Test-Path -Path $path)) {
            Write-Error -Message ("Specified path cannot be found: {0}" -f $path)
            return
        } else {
            $template = Get-Content -Path $path -Raw
        }
    }

    # Determine if the parent path of the target exists, if one has been specified
    if (![String]::IsNullOrEmpty($target)) {
        $parentPath = Split-Path -Path $target -Parent
        if (!(Test-Path -Path $parentPath)) {
            Write-Error -Message ("Directory for target path does not exist: {0}" -f $parentPath)
        }
    }

    # Get all the enviornment variables
    $envvars = [Environment]::GetEnvironmentVariables()

    # iterate around the variables and create local ones
    foreach ($envvar in $envvars.GetEnumerator()) {
        if (@("path", "home") -notcontains $envvar.Name) {
            Set-Variable -Name $envvar.Name -Value $envvar.Value
        }
    }

    # If the additional hashtable contains data then add these as local variables
    if ($additional.Count -gt 0) {
        foreach ($extra in $additional.GetEnumerator()) {
            Set-Variable -Name $extra.Name -Value $extra.Value
        }
    }

    # Perform the expansion of the template
    $data = $ExecutionContext.InvokeCommand.ExpandString($template)

    
    # Output information if show has been specified
    if ($show) {
        Write-Information -MessageData ("base yaml: {0}" -f $path)
        Write-Information -MessageData ("out_template yaml: {0}" -f $target)
    }

    # if the target has been specfied write it out to the file
    if ($pipeline) {
        $data
    } else {

        if ([String]::IsNullOrEmpty($target)) {
            # use the path in the specified to work out the target
            $filename = Split-Path -Path $path -Leaf
            $dir = Split-Path -Path $path -Parent

            # Create the target
            $target = [IO.Path]::Combine($dir, ($filename -replace "base_", ""))

            Write-Information -MessageData ("Setting target path: {0}" -f $target)
        }

        Set-Content -Path $target -Value $data   
    }
}

