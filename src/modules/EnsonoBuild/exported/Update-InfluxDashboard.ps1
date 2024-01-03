function Update-InfluxDashboard() {

    <#

    .SYNOPSIS
    Update Deployment Dashboard Details

    .DESCRIPTION
    With pielines being defined as code, it has become more difficult to show visually what applications have
    been deployed in what environment. This cmdlet uses InfluxDB to create a dashboard of applications and 
    which version has been deployed into each environment.

    This function will send data to an InfluxDB (a time based database) so that a dahsboard can be generated. This
    can be achieved using InfluxDB or Grafana Cloud for example.

    All of the parameters can be defined as envrionment variables, as detailed in the parameters section.

    An InfluxDB account must exist and a TOKEN for the specified ORG supplied.

    #>

    [CmdletBinding()]
    param (
        [string]
        # measurement name in deployment dashboard
        $measurement = $env:DASHBOARD_MEASUREMENT,

        [string]
        # comma separated list of tags to attach to the entry in the deployment dashboard i.e.  environment=dev,source=develop
        $tags = $env:DASHBOARD_TAGS,

        [string]
        # version attached to the entry in the deployment dashboard
        $version = $env:DASHBOARD_VERSION,

        [string]
        # server endpoint
        $influx_server = $env:DASHBOARD_INFLUX_SERVER,

        [string]
        # Token for use with InfluxDB instance
        $influx_token = $env:DASHBOARD_INFLUX_TOKEN,

        [string]
        # Organisation Reference for InfluxDB
        $influx_org = $env:DASHBOARD_INFLUX_ORG,

        [string]
        # Bucket Name for InfluxDB
        $influx_bucket = $env:DASHBOARD_INFLUX_BUCKET,

        [string]
        # Whether we should actually push data for this release
        $publishRelease = $env:PUBLISH_RELEASE
    )

    # Check whether we should actually publish
    if ($publishRelease -ne "true" -Or $publishRelease -ne $true) {
        Write-Information -MessageData ("Neither publishRelease parameter nor PUBLISH_RELEASE environment variable set to `'true`', exiting.")
        return
    }
    
    # Validate all parameters are supplied
    $result = Confirm-Parameters -list @("measurement", "tags", "version", "influx_server", "influx_token", "influx_org", "influx_bucket")
    if (!$result) {
        Write-Error -Message "Missing parameters"
        return
    }



    # Confirm influx server is HTTPS web address
    $result = $false
    $result = Confirm-IsWebAddress $influx_server
    if (!$result) {
        Write-Information -MessageData ("influx server: {0}" -f $influx_server)
        Write-Error -Message "supplied server parameter is not a valid HTTPS address"
        return
    }
    Write-Information -MessageData ("Influx Server: {0} is a valid web address" -f $influx_server)

    # Test the deploymentTags are a valid comma separated list
    $result = $false
    $result = Confirm-CSL $tags
    if (!$result) {
        Write-Information -MessageData ("tags: {0}" -f $tags)
        Write-Error -Message "tags parameter is not a valid comma-separated list as a string"
        return
    }
    Write-Information -MessageData ("tags {0} is a valid comma-separated list as a string" -f $tags)

    # Test the version is a valid semantic version syntax
    $result = $false
    $result = Confirm-SemVer $version
    if (!$result) {
        Write-Information -MessageData ("version: {0}" -f $version)
        Write-Error -Message "Influx Version is not a valid semantic version string"
        return
    }
    Write-Information -MessageData ("{0} is a valid semantic version string" -f $version)

    # Generate the request URI
    $uri = "{0}/api/v2/write?org={1}&bucket={2}" -f $influx_server,$influx_org,$influx_bucket
    
    Write-Information -MessageData ("URI: {0}" -f $uri)

    # Generate the headers
    $headers = @{   "Authorization" = "Token $influx_token"
                    "Accept" = "application/json"
                    "Content-Type" = "text/plain; charset=utf-8"
                }
    # Generate the request body
    $object = $tags -split ","
    $object = ,"$measurement" + $object
    $tags = $object -join ","
    $body = "$tags" + " version=`"$version`""
    
    # Invoke-RestMethod on InfluxDB endpoint
    try     { Invoke-RestMethod -Method POST -Header $headers -uri $uri -body $body 
            Write-Information "InfluxDB Updated" }
    catch   { Write-Error $_
            return }
}
