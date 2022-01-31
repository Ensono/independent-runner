function Invoke-SonarScanner() {
    [CmdletBinding()]
    param (

        [Switch]
        # Start the sonarcloud analysis
        $start,

        [Switch]
        # Stop the analysis
        $stop,

        [string]
        # Project name
        $ProjectName = $env:PROJECT_NAME,

        [string]
        # build version
        $BuildVersion = $env:BUILD_BUILDNUMBER,

        [Alias("Host")]
        [string]
        # Sonar Host
        $URL = $env:SONAR_URL,

        [Alias("Organization")]
        [string]
        # Organisation
        $Organisation = $env:SONAR_ORG,

        [string]
        # Security Token
        $Token = $env:SONAR_TOKEN,

        [string]
        # Additional run properties
        $Properties = $env:SONAR_PROPERTIES
    )

    # The token is mandatory, but need to check the environment variables
    # to see if a token has been set
    if ([string]::IsNullOrEmpty($Token)) {
        $Token = $env:SONAR_TOKEN
    }

    # If the token is still empty then throw an error
    if ([string]::IsNullOrEmpty($Token)) {
        Write-Error -Message "A Sonar token must be specified. Use -Token or set SONAR_TOKEN env var"
        return
    }

    if ($start.IsPresent -and $stop.IsPresent) {
        Write-Error -Message "Please specify -start or -stop, not both"
        return
    }

    # Look for the sonarscanner command
    $tool = Find-Command -name "dotnet-sonarscanner"

    # Depending on the modethat has been set, define the command that needs to be run
    if ($start.IsPresent) {

        # Ensure that all the required parameters are specified
        # This is done because the Mandatory check on the parameter does not take into account
        # values from the environment
        $result = Confirm-Parameters -List @("ProjectName", "BuildVersion", "Organisation")
        if (!$result) {
            return
        }

        # Build up the command to run
        # Use an array to this with each option so that items can be easily changed and connected together
        $arguments = @()
        $arguments += "/k:{0}" -f $ProjectName
        $arguments += "/v:{0}" -f $BuildVersion
        $arguments += "/d:sonar.host.url={0}" -f $URL
        $arguments += "/o:{0}" -f $Organisation
        $arguments += "/d:sonar.login={0}" -f $Token
        if (![string]::IsNullOrEmpty($Properties)) {
            $arguments += $Properties
        }

        $cmd = "{0} begin {1}" -f $tool, ($arguments -Join " ")

    }

    if ($stop.IsPresent) {
        $arguments = @()
        $arguments += "/d:sonar.login={0}" -f $Token
        if (![string]::IsNullOrEmpty($Properties)) {
            $arguments += $Properties
        }

        $cmd = "{0} end {1}" -f $tool, ($arguments -Join " ")
    }

    Invoke-External -Command $cmd

    $LASTEEXITCODE
}