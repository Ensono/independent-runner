
# Get a list of the functions that need to be part of the module
$functions = Get-ChildItem -Recurse $PSScriptRoot -Include *.ps1 | Where-Object { $_ -notmatch "Providers" -and $_ -notmatch "\.Tests\.ps1"}

# source each of the individual scripts
foreach ($function in $functions) {
    . $function.FullName
}

$Session = @{
    commands = @{
        list = @()
        exitcodes = @()
        file = ""
    }
}

# Enable Information messages to be displayed
$InformationPreference = "Continue"

# Determine the list of functions that need to be made available
#$functions_to_export = $functions | Where-Object { $_.FullName -match "Exported" } | ForEach-Object { $_.Basename }

# Export the accessible functions
#Export-ModuleMember -function ( $functions_to_export )
