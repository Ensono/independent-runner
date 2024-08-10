
function Set-Tokens {

    <#
    
    .SYNOPSIS
    Returns a hashtable of all the environment variables and their values

    .DESCRIPTION
    The Indepedent Runner uses a number of environment variables to pass information around. It also allows
    many substititions to be made so that configuration is more dynamic.

    This cmdlet adds all of the envireonment variables in the session to a hashtable and returns it as a key
    value pair. Named environment variables can be excluded from the list, as we well as partial matches on the 
    name based on a Regex pattern.

    Optionally the names of the environment variables can be converted to lowercase so that there is a consistent
    format to all of the tokens

    #>

    [CmdletBinding()]
    param (

        [string]
        [Alias("BuildNumber")]
        # Version number to apply to the generated documentation
        $Version = $(if ([String]::IsNullOrEmpty($env:BUILDNUMBER)) { $env:VERSION } else { $env:BUILDNUMBER }),

        [hashtable]
        # Extra tokens that need to be added to the tokens array
        $ExtraTokens = @{},

        [string[]]
        # Environment variables to exclude from the tokens list
        $Exclude = @(),

        [switch]
        # Specify if the tokens should be converted to lowercase
        $Lower
    )

    $tokens = @{}

    # Add all environment variables to the tokens list
    # This is so that any can be used in substitutions in the generation of an AsciiDoc document
    $envs = Get-ChildItem -Path env:*
    foreach ($env in $envs) {

        # Only add the environment variable if it is not in the exclude list
        if ($Exclude -match $env.Name) {
            continue
        }

        # Get the name of envvar
        $env_name = $env.Name
        if ($Lower) {
            $env_name = $env_name.ToLower()
        }

        $tokens[$env_name] = $env.Value
    }

    # Add any extra tokens that have been passed in
    foreach ($key in $ExtraTokens.Keys) {

        # Get the name of the key
        $key_name = $key
        if ($Lower) {
            $key_name = $key_name.ToLower()
        }

        $tokens[$key_name] = $ExtraTokens[$key]
    }

    # If a version has been specified then add to the token list
    # There could be a situation where the version gets overridden as it has been set in
    # an environment variable but also excplicitly to this cmdlet.
    if (![String]::IsNullOrEmpty($Version)) {
        $tokens["version"] = $Version
    }

    # Return the tokens
    return $tokens
}