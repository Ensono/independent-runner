<#

.SYNOPSIS
Create a Docker image for the application and optionally pushes it to a container registry

.DESCRIPTION
Builds a docker image using the specified build arguments, name and tags. Optionally the function
can also push the image to a remote registry.

If the option has been specified to push to a remote registry then a name of the regsitry
and the group it belongs to need to be specified.

The parameters can be specified on the command line or as an environment variable, apart from the
buildargs and whether the image should be pushed to a registry.

In order to push to a registry the function will first use the Connect-Azure function and then
get the regsitry credentials using the Get-AzContainerRegistryCredential cmdlet.

#>

function Build-DockerImage() {
    [CmdletBinding()]
    param (

        [string]
        # Arguments for docker build
        $buildargs = ".",

        [string]
        # Name of the docker image
        $name = $env:DOCKER_IMAGE_NAME,

        [string]
        # Image tag
        $tag = $env:DOCKER_IMAGE_TAG,

        [Parameter(
            ParameterSetName="push"
        )]
        [string]
        # Docker registry FQDN to push the image to
        $registry = $env:DOCKER_CONTAINER_REGISTRY_NAME,

        [string]
        # Resource group the container registry can be found in
        $group = $env:REGISTRY_RESOURCE_GROUP,

        [Parameter(
            ParameterSetName="push"
        )]
        [switch]
        # Push the image to the specified registry
        $push,
        [Parameter(
            ParameterSetName="push"
        )]
        [switch]
        # Push the image to a generic, non-Azure registry.
        # Make sure you have env vars for DOCKER_PASSWORD and DOCKER_USERNAME.
        $generic,
        [Parameter(
            ParameterSetName="push"
        )]
        [switch]
        # Add the latest tag
        $latest
    )

    # Check mandatory parameters
    # This is not done at the param level because even if an environment
    # variable has been set the parameter will not see this as a value
    if ([string]::IsNullOrEmpty($name)) {
        Write-Error -Message "A name for the Docker image must be specified"
        return
    }

    if ([string]::IsNullOrEmpty($tag)) {
        $tag = "0.0.1-workstation"
        Write-Information -MessageData ("No tag has been specified for the image, a default one has been set: {0}" -f $tag)
    }

    # If the push switch has been specified then check that a registry
    # has been specified
    if ($push.IsPresent -and [string]::IsNullOrEmpty($registry) -and !(Test-Path -Path env:\NO_PUSH)) {
        Write-Error -Message "A registry to push the image to must be specified"
        return
    }

    if ($generic.IsPresent -and ([string]::IsNullOrEmpty($env:DOCKER_USERNAME) -Or [string]::IsNullOrEmpty($env:DOCKER_PASSWORD))) {
        Write-Error -Message "Pushing to a generic registry requires environment variables DOCKER_USERNAME and DOCKER_PASSWORD to be set"
        return
    }

    # Ensure that the name and the tagare lowercase so that Docker does not 
    # throw an error with invalid strings
    $name = $name.ToLower()
    $tag = $tag.ToLower()

    # Create an array to store the arguments to pass to docker
    $arguments = @()
    $arguments += $buildArgs
    $arguments += "-t {0}:{1}" -f $name, $tag

    # if the registry name has been set, add t to the tasks
    if (![String]::IsNullOrEmpty($registry)) {
        $arguments += "-t {0}/{1}:{2}" -f $registry, $name, $tag
        $arguments += "-t {0}/{1}:latest" -f $registry, $name
    }

    # Create the cmd to execute
    $cmd = "docker build {0}" -f ($arguments -Join " ")
    Invoke-External -Command $cmd

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    # Proceed if a registry has been specified
    if (![String]::IsNullOrEmpty($registry) -and $push.IsPresent -and !(Test-Path -Path env:\NO_PUSH)) {

        if (!$generic) {
            # Ensure that the module is available and loaded
            $moduleName = "Az.ContainerRegistry"
            $module = Get-Module -ListAvailable -Name $moduleName
            if ([string]::IsNullOrEmpty($module)) {
                Write-Error -Message ("{0} module is not available" -f $moduleName)
                exit 2
            } else {
                Import-Module -Name $moduleName
            }

            # Login to azure
            Connect-Azure

            # Rewrite Registry value to obtain Azure Resourece Name:
            $registryName = $registry.split(".")[0]

            # Get the credentials for the registry
            $creds = Get-AzContainerRegistryCredential -Name $registryName -ResourceGroup $group
        
            $cmd = "docker login {0} -u {1} -p {2}" -f $registry, $creds.UserName, $creds.Password

        } else {
            $cmd = "docker login {0} -u {1} -p {2}" -f $registry, $env:DOCKER_USERNAME, $env:DOCKER_PASSWORD
        }
        # Run command to login to the docker registry to do the push
        # The Invoke-External function will need to be updated to obfruscate sensitive information
        Invoke-External -Command $cmd

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        # Push the image with the desired tag
        $cmd = "docker push {0}/{1}:{2}" -f $registry, $name, $tag
        Invoke-External -Command $cmd

        # Push the image with the latest tag if latest flag is declared
        if ($latest.IsPresent) {
            $cmd = "docker push {0}/{1}:latest" -f $registry, $name
            Invoke-External -Command $cmd
        }

        $LASTEXITCODE

    }
}
