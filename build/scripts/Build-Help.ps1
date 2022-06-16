
[CmdletBinding()]
param (

    [string]
    # Path that the help should be written to
    $output = "${PSScriptRoot}/../../docs/reference"
)

# Ensure that the output folder exists
if (!(Test-Path -Path $output)) {
    New-Item -Type Directory -Path $output
}

# Import the module so that all the functions ar available
Import-Module ${PSScriptRoot}/../../src/modules/AmidoBuild -Force

# Iterate around all of the exported functions and get the help for each one
$exported = (Get-Module AmidoBuild).ExportedCommands
foreach ($item in $exported.GetEnumerator()) {
    
    # Create the path to the file to create
    $path = [IO.Path]::Combine($output, ("{0}.adoc" -f $item.Value))

    # Get the help for the function and output to the file
    Get-Help -Name $item.Value | Out-File -Path $path

}