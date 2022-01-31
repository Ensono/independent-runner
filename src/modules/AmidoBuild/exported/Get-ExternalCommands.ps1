
<#

.SYNOPSIS
    Function to return a list of the external commands that have been executed by the module

#>
function Get-ExternalCommands() {

    [CmdletBinding()]
    param (

        [int]
        # Retrieve specified command item
        $item
    )

    $exists = Get-Variable -Name "Session" -Scope global -ErrorAction SilentlyContinue

    # return the commands in the session if the session var exists
    if (![String]::IsNullOrEmpty($exists)) {

        # if there are no commands in the list, display a warning
        if ($global:Session.commands.list.Count -eq 0) {
            Write-Warning -Message "No commands have been executed"
        } else {

            if ($item -gt 0) {
                
                # Raise an error if the item is greater than the number of items
                if ($item -gt $global:Session.commands.list.count) {
                    Write-Error -Message ("Specified item does not exist: {0} total" -f $global:Session.commands.list.count)
                } else {
                    $global:Session.commands.list[$item - 1]
                }
            } else {
                $global:Session.commands.list
            }
        }
        
    } else {
        Write-Warning -Message "Session has not been defined"
    }
}