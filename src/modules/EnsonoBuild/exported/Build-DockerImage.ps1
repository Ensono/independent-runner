function Build-DockerImage() {

  <#

    .SYNOPSIS
    Create a Docker image for the application and optionally pushes it to a container registry

    .DESCRIPTION
    Builds a docker image using the specified build arguments, name and tags. Optionally the function
    can also push the image to a remote registry, be it a generic registry, Azure or AWS.

    If the option has been specified to push to a remote registry then a name of the registry
    and the group it belongs to need to be specified.

    The parameters can be specified on the command line or as an environment variable, apart from the
    buildargs and whether the image should be pushed to a registry.

    In order to push to a registry the function will first use the Connect-Azure function and then
    get the regsitry credentials using the Get-AzContainerRegistryCredential cmdlet.

    AWS command reference: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html

    .EXAMPLE

    Build-DockerImage -Provider azure -Name ensonodigital/myimage:0.0.1 -Registry edregistry.azurecr.io -buildargs src/api -push

    This will build a DockerImage using the Dockefile in the current directory. The build arguments will be passed and then once
    the image has been built it will be pushed to the specified Azure registry.

    The username and password to access the registry will be extracted using the PowerShell cmdlet `Get-AzContainerRegistryCredential`
    and then this will be passed to the resultant docker command.
  #>

  [CmdletBinding()]
  param (
    [Parameter(
      ParameterSetName = "build"
    )]
    [string]
    # Arguments for docker build
    $buildargs = ".",

    [Parameter(
      ParameterSetName = "build",
      Mandatory = $true
    )]
    [string]
    # Name of the docker image
    $name = $env:DOCKER_IMAGE_NAME,

    [Parameter(
      ParameterSetName = "build"
    )]
    [string]
    # Image tag
    $tag = $env:DOCKER_IMAGE_TAG,

    [Parameter(
      ParameterSetName = "build"
    )]
    [switch]
    # Add the latest tag
    $latest,

    [Parameter(
      ParameterSetName = "build"
    )]
    [Parameter(
      ParameterSetName = "push"
    )]
    [string]
    # Docker registry FQDN to push the image to. For AWS this is in the format `<aws_account_id>.dkr.ecr.<region>.amazonaws.com`. For Azure this is in the format `<acr_name>.azurecr.io`
    $registry = $env:DOCKER_CONTAINER_REGISTRY_NAME,

    [Parameter(
      ParameterSetName = "build"
    )]
    [Parameter(
      ParameterSetName = "push"
    )]
    [switch]
    # Push the image to the specified registry
    $push,

    [Parameter(
      ParameterSetName = "build"
    )]
    [string[]]
    # List of archiectures that need to be built
    $platforms = $env:PLATFORMS,

    [Parameter(
      ParameterSetName = "build"
    )]
    [string[]]
    # Builder to use when creating the image
    $builder = $env:BUILDX_BUILDER,

    [string]
    [Parameter(
      ParameterSetName = "build"
    )]
    [Parameter(
      ParameterSetName = "push"
    )]
    [Parameter(
      ParameterSetName = "aws"
    )]
    [Parameter(
      ParameterSetName = "azure"
    )]
    [ValidateSet('azure', 'aws', 'generic')]
    # Determine which provider to use for the push
    $provider,

    [string]
    [Parameter(
      ParameterSetName = "build"
    )]
    [Parameter(
      ParameterSetName = "azure"
    )]
    [Parameter(
      ParameterSetName = "push"
    )]
    # Resource group  in Azure that the container registry can be found in
    $group = $env:REGISTRY_RESOURCE_GROUP,

    [string]
    [Parameter(
      ParameterSetName = "build"
    )]
    [Parameter(
      ParameterSetName = "aws"
    )]
    [Parameter(
      ParameterSetName = "push"
    )]
    # Region in AWS that the container registry can be found in
    $region = $env:ECR_REGION,

    [switch]
    # If used with -latest it will force the latest tag onto the image regardless
    # of the branch that has been detected
    $force
  )

  # Declare variables
  # State if the build should also push the image
  $build_and_push = $false

  # Check mandatory parameters
  # This is not done at the param level because even if an environment
  # variable has been set the parameter will not see this as a value
  if ([string]::IsNullOrEmpty($name)) {
    Write-Error -Message "A name for the Docker image must be specified"
    return 1
  }

  if ([string]::IsNullOrEmpty($tag)) {
    $tag = "0.0.1-workstation"
    Write-Information -MessageData ("No tag has been specified for the image, a default one has been set: {0}" -f $tag)
  }

  # set a default for the platforms if none have been set
  if ([string]::IsNullOrEmpty($platforms)) {
    $platforms = @("linux/arm64", "linux/amd64")
  }

  # If the push switch has been specified then check that a registry
  # has been specified
  if ($push.IsPresent -and ([string]::IsNullOrEmpty($provider) -or ([string]::IsNullOrEmpty($registry) -and !(Test-Path -Path env:\NO_PUSH)))) {
    Write-Error -Message "A provider and a registry to push the image to must be specified"
    return 1
  }

  if ($provider -eq "generic" -and ([string]::IsNullOrEmpty($env:DOCKER_USERNAME) -Or [string]::IsNullOrEmpty($env:DOCKER_PASSWORD)) -and !(Test-Path -Path env:\NO_PUSH)) {
    Write-Error -Message "Pushing to a generic registry requires environment variables DOCKER_USERNAME and DOCKER_PASSWORD to be set"
    return
  }

  elseif ($provider -eq "azure" -and ([string]::IsNullOrEmpty($env:REGISTRY_RESOURCE_GROUP)) -and ([string]::IsNullOrEmpty($group))) {
    Write-Error -Message "Pushing to an azure registry requires environment variable REGISTRY_RESOURCE_GROUP or group parameter to be set (authentication must be dealt with via 'invoke-login.ps1'"
    return
  }

  elseif ($provider -eq "aws" -and ([string]::IsNullOrEmpty($env:AWS_ACCESS_KEY_ID) -Or [string]::IsNullOrEmpty($env:AWS_SECRET_ACCESS_KEY) -Or ([string]::IsNullOrEmpty($region) -And [string]::IsNullOrEmpty($env:ECR_REGION)))) {
    Write-Error -Message "Pushing to an AWS registry requires environment variable ECR_REGION or region parameter defined, and both environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to be set"
    return
  }

  # Run commands to peform the login to the target registry
  # This has to be done before the build command as that is reponsible for pushing the image as well
  if (![String]::IsNullOrEmpty($registry) -and $push.IsPresent -and !(Test-Path -Path env:\NO_PUSH)) {

    switch ($provider) {
      "azure" {
        # Ensure that the module is available and loaded
        $moduleName = "Az.ContainerRegistry"
        $module = Get-Module -ListAvailable -Name $moduleName
        if ([string]::IsNullOrEmpty($module)) {
          Write-Error -Message ("{0} module is not available" -f $moduleName)
          exit 2
        }
        else {
          Import-Module -Name $moduleName
        }

        # Login to azure
        Connect-Azure

        # Rewrite Registry value to obtain Azure Resourece Name:
        $registryName = $registry.split(".")[0]

        # Get the credentials for the registry
        $creds = Get-AzContainerRegistryCredential -Name $registryName -ResourceGroup $group

        $cmd = "docker login {0} -u {1} -p {2}" -f $registry, $creds.UserName, $creds.Password

      }
      "generic" {
        $cmd = "docker login {0} -u {1} -p {2}" -f $registry, $env:DOCKER_USERNAME, $env:DOCKER_PASSWORD
      }
      "aws" {

        $cmd = "aws ecr get-login-password --region {0} | docker login --username AWS --password-stdin {1}" -f $region, $registry

      }
    }

    # Run command to login to the docker registry to do the push
    # The Invoke-External function will need to be updated to obfruscate sensitive information
    Invoke-External -Command $cmd

    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }

    # Set the build_+and_push to tru
    $build_and_push = $true

  }

  # Determine if latest tag should be applied
  $setAsLatest = $false
  if (((Confirm-TrunkBranch) -or $force.IsPresent) -and $latest.IsPresent) {
    $setAsLatest = $true
  }

  # Ensure that the name and the tagare lowercase so that Docker does not
  # throw an error with invalid strings
  $name = $name.ToLower()
  $tag = $tag.ToLower()

  # Create an array to store the arguments to pass to docker
  $arguments = @()
  $arguments += $buildArgs.Trim("`"", " ")
  $arguments += "-t {0}:{1}" -f $name, $tag

  # if the registry name has been set, add t to the tasks
  if (![String]::IsNullOrEmpty($registry)) {
    $arguments += "-t {0}/{1}:{2}" -f $registry, $name, $tag

    if ($setAsLatest) {
      $arguments += "-t {0}/{1}:latest" -f $registry, $name
    }
  }

  # Add in the platforms that need to be built
  $arguments += "--platform {0}" -f ($platforms -join ",")

  # If a builder has been specified, add it to the arguments
  if (!([string]::IsNullOrEmpty($builder))) {
    $arguments += "--builder {0}" -f $builder
  }

  # Add push to the arguments if needed
  if ($build_and_push) {
    $arguments += "--push"
  }

  # Create the cmd to execute
  $cmd = "docker buildx build {0}" -f ($arguments -Join " ")
  Invoke-External -Command $cmd

  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

}
