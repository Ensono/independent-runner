function Invoke-SonarScanner() {

    <#
    
    .SYNOPSIS
    Starts or stops the SonarScanner utility when running a build and tests

    .DESCRIPTION
    When running build SonarScanner can be started so that it checks the code for
    vulnerabilities. This is invaluable when building applicatios to minimise risk
    in the final application.

    SonarScanner works by starting the process which then runs in the background.
    The build and the tests are then executed and when they are complete the SonarScanner
    process is stopped, at which point the results and analysed and report is generated.

    This command uses Sonar Cloud so it needs to have a token for credentials as well
    as the name of the project and the organisation for which the scan is being performed.

    .NOTES
    If using this tool as part of a Stacks pipeline and thus using Taskctl, all of the commands
    need to be wrapped together in the same task. This is because the start process of 
    SonarScanner sets up the environment for it to be able to check the build and tests. If this
    is run in a separate task to the build then the environment is lost.

    The way around this is to run everything in the same task, for example:

    [source,powershell]
    ---
    Invoke-SonarScanner -start &&
    Invoke-DotNet -Build -Path $env:SELF_REPO_SRC &&
    Invoke-DotNet -Tests -pattern "*UnitTests" -arguments "--logger 'trx' --results-directory /app/testresults -p:CollectCoverage=true -p:CoverletOutputFormat=opencover -p:CoverletOutput=/app/coverage/" &&
    Invoke-DotNet -Tests -pattern "*ComponentTests" -arguments "--logger 'trx' --results-directory /app/testresults -p:CollectCoverage=true -p:CoverletOutputFormat=opencover -p:CoverletOutput=/app/coverage/" &&
    Invoke-DotNet -Tests -pattern "*ContractTests" -arguments "--logger 'trx' --results-directory /app/testresults -p:CollectCoverage=true -p:CoverletOutputFormat=opencover -p:CoverletOutput=/app/coverage/" &&
    Invoke-DotNet -Coverage -target /app/coverage &&
    Remove-Item Env:\SONAR_PROPERTIES &&
    Invoke-SonarScanner -stop
    ---

    .EXAMPLE
    Invoke-SonarScanner -start -projectname myproject -org myorg -buildversion 100.98.99 -url "https://sonarscanner.example" token 122345
    --Run build and tests--
    Invoke-SonarScanner -stop -token 122345

    Starts the SonarScanner with the necessary properties set on the command line. The
    build and tests and then run and the process is stopped using the same token as before.

    .EXAMPLE
    $env:PROJECT_NAME = "myproject"
    $env:BUILD_BUILDNUMBER = "100.98.99"
    $env:SONAR_ORG = "myorg"
    $env:URL = "https://sonarscanner.example"
    $env:SONAR_TOKEN = "122345"
    Invoke-SonarScanner -start
    --Run build and tests--
    Invoke-SonarScanner -stop

    Performs the same process as the previous example, except that everything required is
    specified using environment variables. This is useful so that information about
    the access to SonardCloud is not accidentally leaked into the logs
    
    #>

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
        $arguments += "/d:sonar.token={0}" -f $Token
        if (![string]::IsNullOrEmpty($Properties)) {
            $arguments += $Properties
        }

        $cmd = "{0} begin {1}" -f $tool, ($arguments -Join " ")

    }

    if ($stop.IsPresent) {
        $arguments = @()
        $arguments += "/d:sonar.token={0}" -f $Token
        if (![string]::IsNullOrEmpty($Properties)) {
            $arguments += $Properties
        }

        $cmd = "{0} end {1}" -f $tool, ($arguments -Join " ")
    }

    Invoke-External -Command $cmd

    $LASTEEXITCODE
}
