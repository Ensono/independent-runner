function Deploy-AzFunction() {

  [CmdletBinding()]
  param (

      [string]
      $function_name,
      [string]
      $function_rg,
      [string]
      $docker_image_name,
      [string]
      $docker_image_tag,
      [string]
      $docker_server_url,
      [boolean]
      $generate_acr_creds = $true,
      [string]
      $docker_registry_username,
      [string]
      $docker_registry_key,
      [switch]
      $azcli
  )

  if ($azcli.IsPresent) {
    If ($generate_acr_creds) {
        $registryCredentials = (
          az acr credential show `
            --name $(docker_server_url) `
          | ConvertFrom-Json
        )
        $docker_registry_username = $registryCredentials.username
        $docker_registry_key = $registryCredentials.passwords[0].value
        }

      az functionapp config container set `
        --resource-group $function_rg `
        --name $function_name `
        --docker-registry-server-url https://$docker_server_url `
        --docker-registry-server-user $docker_registry_username `
        --docker-registry-server-password $docker_registry_key

      } else {
    If ($generate_acr_creds) {
      $creds = $(Get-AzContainerRegistryCredential -name amidostacksnonprodeuwcore -resourcegroupname amido-stacks-nonprod-euw-core)
      $securePassword = ConvertTo-Securestring $creds.Password -AsPlainText -Force
    }

    Set-AzWebApp -ResourceGroupName amido-stacks-dev-euw-netcore-api-cqrs-evnts `
    -Name func-asb-listener-nwhujo `
    -ContainerImageName amidostacksnonprodeuwcore.azurecr.io/stacks-api-events-listener-asb-function:6.0.376-master `
    -ContainerRegistryPassword $securePassword `
    -ContainerRegistryUser $creds.Username `
    -ContainerRegistryUrl http://amidostacksnonprodeuwcore.azurecr.io

    Start-AzWebAppSlot
    Switch-AzWebAppSlot
    Restart-AzWebAppSlot
    Stop-AzWebAppSlot
    }

