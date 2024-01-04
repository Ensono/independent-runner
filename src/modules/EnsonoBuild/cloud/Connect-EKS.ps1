
function Connect-EKS() {

  <#

  .SYNOPSIS
  Connect to azure using environment variables for the parameters

  .DESCRIPTION
  In order to access EKS, one must run external command `aws eks`. In order to
  match the protocol used for Connect-Azure, this is exported to separate function.

  This function is not exported outside of the module.

  .EXAMPLE

  Connect to Azure using parameters set on the command line

  Connect-EKS -name cluster -region eu-west-2


  #>

  [CmdletBinding()]
  param (

      [Alias("cluster")]
      [string]
      # Name of the cluster
      $name,

      [string]
      # Region the cluster is deployed into
      $region = "eu-west-2",

      [switch]
      # Whether to dry run the command
      $dryrun = $false
  )

  # Ensure that all the required parameters have been set
  foreach ($parameter in @("name", "region")) {

    # check each parameter to see if it has been set
    if ([string]::IsNullOrEmpty((Get-Variable -Name $parameter).Value)) {
        $missing += $parameter
    }
  }

  # if there are missing parameters throw an error
  if ($missing.length -gt 0) {
      Write-Error -Message ("Required parameter/s are missing: {0}" -f ($missing -join ", "))
  } else {

    $cmd = "aws eks update-kubeconfig --name {0} --region {1}" -f $name, $region
    Invoke-External $cmd
  }
}
