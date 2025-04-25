

function Build-PowerShellModule() {

    <#

    .SYNOPSIS
    Function to create the EnsonoBuild PowerShell module

    .DESCRIPTION
    The powershell module in this repository is used with the Independent Runner
    so that all commands and operations are run in the same way regardless of the platform.

    The cmdlet can be used to build any PowerShell module as required.

    PowerShell modules can be deployed as multiple files or as a single file in the `.psm1` file.
    To ease deployment, the module will bundle all of the functions into a single file. This means
    that when it comes to deployment there are only two files that are required, the manifest file
    and the data file.

    .EXAMPLE

    Build-PowerShellModule -Path /app/src/modules -name EnsonoBuild -target /app/outputs/module

    This is the command that is used to build the Independent Runner. It use the path and the name to
    determine where the files for the module. The resultant module will be saved in the specified
    target folder.

    #>

    [CmdletBinding()]
    param (

        [string]
        # Name of the module
        $name,

        [Alias("source")]
        [string]
        # Path to the module files to package up
        $path,

        [Alias("output")]
        [string]
        # Target for the "compiled" PowerShell module
        $target = "outputs",

        [Hashtable]
        # Hashtable to be put in as the global session for the module
        $sessionObject = @{},

        [string]
        # Name of the global session to create
        $sessionName,

        [string]
        # Version number to assign to the module
        $version = $env:MODULE_VERSION
    )

    # Check that all the necessary parameters have been set
    $result = Confirm-Parameters -list @("name", "path", "target")
    if (!$result) {
        return $false
    }

    # Check that the path exists
    if (!(Test-Path -Path $path)) {
        Write-Error -Message ("Specified module path does not exist: {0}" -f $path)
        return $false
    }

    # Check that the target path exists
    $target = [IO.Path]::Combine($target, $name)
    if (!(Test-Path -Path $target)) {

        $result = Protect-Filesystem -Path $target -BasePath (Get-Location).Path
        if (!$result) {
            return $false
        }
    }

    # work out the path to the module
    $moduleDir = [IO.Path]::Combine($path, $name)

    # Check that the PSD file can be found
    $modulePSD = [IO.Path]::Combine($moduleDir, ("{0}.psd1" -f $name))
    if (!(Test-Path -Path $modulePSD)) {
        Write-Error -Message ("Module data file cannot be found: {0}" -f $modulePSD)
        return $false
    }

    # Get all the functions in the module, except the tests
    $splat = @{
        Path = $moduleDir
        ErrorAction = "SilentlyContinue"
        Recurse = $true
        Include = "*.ps1"
    }
    $moduleFunctions = Get-ChildItem @splat | Where-Object { $_ -notmatch "Providers" -and $_ -notmatch "\.Tests\.ps1"}

    Write-Information -MessageData ("Number of functions: {0}" -f $moduleFunctions.length)
    Write-Information -MessageData "Configuring module file"

    # Create the path for the module file
    $modulePSM = [IO.Path]::Combine($target, ("{0}.psm1" -f $name))

    # if a session object and name have been specified add it to the PSM file
    # TODO: write util function to convert the hashtable to a string that can be added to the PSM file
    if (![string]::IsNullOrEmpty($sessionName) -and $sessionObject.Count -gt 0) {
        Add-Content -Path $modulePSM -Value (@"
`${0} = {1}
"@ -f $sessionName, ($sessionObject | Convert-HashToString))

        Add-Content -Path $modulePSM -Value "`n"
    }

    # Iterate around the functions that have been found
    foreach ($moduleFunction in $moduleFunctions) {

        $results = [System.Management.Automation.Language.Parser]::ParseFile($moduleFunction.FullName, [ref]$null, [ref]$null)

        # get all the functions in the file
        $functions = $results.EndBlock.Extent.Text

        # Add the functions to the PSM file
        Add-Content -Path $modulePSM -Value $functions

    }

    Write-Information -MessageData "Updating module data"

    # Copy the datafile into the output dir
    Copy-Item -Path $modulePSD -Destination $target

    # Update the manifest file with the correct list of functions to export
    # and the build number

    # get a list of the functions to export
    $functionsToExport = Get-ChildItem -Recurse $moduleDir -Include *.ps1 | Where-Object { $_.FullName -match "exported" -and $_ -notmatch "\.Tests\.ps1"} | ForEach-Object { $_.Basename }

    $splat = @{
        Path = [IO.Path]::Combine($target, ("{0}.psd1" -f $name))
        FunctionsToExport = $functionsToExport
    }

    # if a version has been specified add it to the splat
    if (![string]::IsNullOrEmpty($version)) {
        $splat["ModuleVersion"] = $version
    }

    Update-ModuleManifest @splat

}
