
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

# Create the file that will be used to handle the index of the reference
$indexLinks = @()
$indexFile = [IO.Path]::Combine($output, "index.adoc")
if (Test-Path -Path $indexFile) {
    Remove-Item -Path $indexFile
}

# Import the module so that all the functions ar available
Import-Module ${PSScriptRoot}/../../src/modules/AmidoBuild -Force

# Create an array to hold the synopsis of each function, this is used
# to provide an index table in the resultant document
$synopsis = @(
    '[cols="1,3",options="header"]',
    "|==="
    "| Name | Synopsis "
)

# Iterate around all of the exported functions and get the help for each one
$exported = (Get-Module AmidoBuild).ExportedCommands
foreach ($item in $exported.GetEnumerator()) {
    
    # Create the path to the file to create
    $path = [IO.Path]::Combine($output, ("{0}.adoc" -f $item.Value))

    # Get the help for the function and output to the file
    $help = Get-Help -Name $item.Value -Detailed 

    # determine the heading id for the function
    $headingId = $help.Name.ToLower() -replace " ", "_"

    # Add to the synopsis array
    $synopsis += "| <<{0}>> | {1} " -f $headingId, $help.synopsis
    
    # iterate around the parameters and build up each row
    $table = @()
    foreach ($param in $help.parameters.parameter) {
        $table += "| {0} | {1} | {2} | {3} | {4}" -f
            $param.Name,
            $param.Type.Name,
            $param.Description.Text,
            $param.Required,
            $param.DefaultValue
    }

    # Build up an array for the page items
    # This is so that different things can be added in if they exist, e.g. Notes or Examples
    $helpPage = @()
    $helpPage += @"
### {0} [[{2}]]

{1}

"@ -f $help.Name, $help.Description.Text, $headingId

    # If any notes have been set add them into the array
    if (![String]::IsNullOrEmpty($help.alertSet.alert.text)) {
        $helpPage += @"
#### Notes

{0}

"@ -f $help.alertSet.alert.text
    } 

    # Add in the synatx of the command
    $helpPage += @"
#### Syntax

{0}

"@ -f ($help.syntax | out-string)

    # Table of the parameters
    $helpPage += @"
#### Parameters

[cols="1,1,2,1,1",options="header"]
|===
| Name | Type | Description | Required | Default
{0}
|===

"@ -f ($table -join "`n")

    # Add in Exmaples if they have been created
    if (![String]::IsNullOrEmpty($help.Examples)) {
        $helpPage += "#### Examples`n"

        foreach ($example in $help.Examples.example) {
            $helpPage += @"
{0}

[source,powershell]
----
{1}
----

{2}

"@ -f $example.title, $example.code, $example.remarks.text[0]
        }
    }

    Set-Content -Value ($helpPage -join "`n") -Path $path

    # Create the string to be added to the index file
    $indexLinks += @"
include::{0}.adoc[]

"@ -f $item.Value


}

# Add the synopsis table to the index file
$synopsis += "|==="
Add-Content -Path $indexFile -Value ($synopsis -join "`n")

Add-Content -Path $indexFile -Value ($indexLinks -join "`n")