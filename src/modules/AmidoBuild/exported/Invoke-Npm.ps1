
function Invoke-Npm() {

    <#
    
    .SYNOPSIS
    Runs the Npm or Npx command to perform a build or a custom execution

    .DESCRIPTION
    This cmdlet executes an `npm` or `npx` command. It has bnuilt in tasks for installing packages,
    performing a build and running a custom comand that is not catered for in the cmdlet.

    When installing packaes the `npm i` command is executed, but if a the `-clean` switch ps provided as well
    this is modifyed to be `npm ci`.

    The build stage is very much influenced by the commands that Nx would generate for a pipeline. In this case
    the following steps are performed:

        - Start NX Cloud agent
        - Start Nx Cloud CI run
        - Perform a lint on the workspace
        - Check the format
        - Perform lint
        - Perform a test
        - Perform the build
        - Stop all NX cloud agents

    The number of agents that are used defaults to 3, but this can be changed using the `-agent` argument.

    Additionally the list of tasks that are run can be influenced by providiung a comma delimited list of the tasks
    that are to be run. By default all tasks are executed. Some tasks are run regartedless, these are to do
    with the setup and teardown of the agents in for Nx. A view ofd the tasks that will be run can be viewed by running
    `Invoke-Npm -view`

    The cmdlet supports cutsom execution so that tasks that are not currently supported can be run via the command.

    Due to the way in which the cmdlets are executed by the Independent Runner, this cmdlet maintaains a list of
    all the commands that need to be run to perform a build. TYhis is done so that all the commaands are executed
    in the same session in the container. The same effect can be achived by using the custom switch of the cmdlet
    and supplying arguments for each, but all the multiple stepss would need to be added to the Taskctl task.

    .NOTES

    When NX is executed to find the affected projects it will attempt to find the head checksum using the command
    `git rev-parse HEAD` if it is not specified to the function. However the base checksum must be specified as this
    can be different based on wether this build is from a PR for example.

    .EXAMPLE

    Invoke-Npm -Install -Clean

    Perform a clean install of the packages that are required for the project (`npm ci`).

    .EXAMPLE

    Invoke-Npm -view

    Display the built in tasks for the cmdlet.

    .EXAMPLE

    Invoke-Npm -Build -AgentCount 4 -BaseSHA "465asdfkjh"

    Start a build using all the built in tasks and use 4 agents

    .EXAMPLE

    Invoke-Npm -Build -AgentCount 2 -Tasks workspace,build -BaseSHA "465asdfkjh"

    Start a built but only run the workspace and build tasks on 2 agents.

    .EXAMPLE

    $env:NX_ACOUNT_COUNT = 2
    $env:NX_TASKS = "workspace,build"
    $env:NX_BASE_SHA = "465asdfkjh"
    Invoke-Bpm -Build

    Perform the same oepration as the prevous example but pass all parameters as environment
    variables

    .EXAMPLE

    Invoke-Npm -Custom -Npx -Arguments "nx-cloud start-ci-run"

    Run a custom NPX command. In this case the command that runs would be `npx nx-cloud start-ci-run`

    .EXAMPLE

    $env:NPM_ARGUMENTS = "nx-cloud start-ci-run"
    Invoke-Npm -Custom -Npx

    Run a custom NPX command using environment variables for configuration. In this case the command
    that runs would be `npx nx-cloud start-ci-run`

    #>

    [CmdletBinding()]
    param (

        [Parameter(
            ParameterSetName="install"
        )]
        [switch]
        # Install packages
        $install,

        [Parameter(
            ParameterSetName="install"
        )]
        [switch]
        # Perform a clean install
        $clean,

        [Parameter(
            ParameterSetName="nxcloud"
        )]
        [switch]
        # Perform a build using Nx cloud
        $build,

        [Parameter(
            ParameterSetName="nxcloud"
        )]
        [int]
        # Number of agents that should be started
        $agentCount = $env:NX_AGENT_COUNT,

        [Parameter(
            ParameterSetName="nxcloud"
        )]
        [string]
        # Base SHA checksun
        $baseSHA = $env:NX_BASE_SHA,

        [Parameter(
            ParameterSetName="nxcloud"
        )]
        [string]
        # Head SHa checksum
        $headSHA = $env:NX_HEAD_SHA,

        [Parameter(
            ParameterSetName="nxcloud"
        )]
        [string]
        # NX cloud tasks that should be run
        $tasks = $env:NX_TASKS,

        [Parameter(
            ParameterSetName="custom-npx"
        )]
        [switch]
        $npx,

        [Parameter(
            ParameterSetName="custom-npm"
        )]
        [switch]
        $npm,

        [Parameter(
            ParameterSetName="custom-npm"
        )]
        [Parameter(
            ParameterSetName="custom-npx"
        )]
        [string]
        $arguments = $env:NPM_ARGUMENTS,

        [Parameter(
            ParameterSetName="view"
        )]
        [switch]
        $view
    )

    # set defaults if they nave not been set
    if ($agentCount -eq 0) {
        $agentCount = 3
    }

    # Find the commands for npm and npx
    $npmCmd = Find-Command -Name "npm"
    $npxCmd = Find-Command -Name "npx"

    # if install has been specified, install packages
    if ($PSCmdlet.ParameterSetName -eq "install") {
        $installArgs = ""

        if ($clean.IsPresent) {
            $installArgs += "c"
        }

        $installArgs += "i"

        Write-Information -MessageData "NPM Install Dependencies"

        # Build up the command that needs to be run
        $cmd = "{0} {1}" -f $npmCmd, $installArgs
        Invoke-External -Command $cmd
    }

    # If the cloud parameterset has been invokved start the agents
    if ($PSCmdlet.ParameterSetName -eq "nxcloud") {

        # If the headSHA has not been specified, work it out using git
        if ([String]::IsNullOrEmpty($headSHA)) {
            $git = Find-Command -Name "git"
            $cmd = "{0} rev-parse HEAD" -f $git
            $headSHA = Invoke-External -Command $cmd
        }

        # Raise an error if the baseSHA has not been set
        if([String]::IsNullOrEmpty($baseSHA)) {
            Write-Error -Message ("Base SHA must be specified using the -baseSHA switch or the NX_BASE_SHA environment variable")
            return
        }        

        # Configure the list of tasks that need to be executed
        $taskList = Get-TaskList

        # check that the tasks has been ste, if not set all to run
        if ([String]::IsNullOrEmpty($tasks)) {
            $tasksToRun = $taskList | Where-Object { $_.AlwaysRun -eq $false } | Foreach-Object { $_.Name }
        } else {
            $tasksToRun = $tasks.Split(",")
        }

        # Iterate around the taskList and execute the tasks that have been selected
        foreach ($task in $taskList) {

            # determine if the task should be run
            if ($tasksToRun -contains $task.Name -or $task.AlwaysRun) {
                Write-Information -MessageData $task.Description
                Invoke-External -Command $task.Cmd
            } else {
                Write-Warning -Message ("Task has been skipped: {0}" -f $task.Name)
            }
        }
    }

    # Run a custom command based on the provided options
    if (@("custom-npm", "custom-npx") -contains $PSCmdlet.ParameterSetName) {

        # set the ocmmand based on the switch
        if ($npm.IsPresent) {
            $cmd = $npmCmd
        } elseif ($npx.IsPresent) {
            $cmd = $npxCmd
        }

        Write-Information -MessageData "Executing custom command"

        $cmd += " {0}" -f $arguments

        Invoke-External -Command $cmd
    }

    # If the view parameter set has been chosen show the tasks in a table
    if ($PSCmdlet.ParameterSetName -eq "view") {
        Get-TaskList | Select-Object -Property Name, Description, AlwaysRun
    }
}

function Get-TaskList() {
    return @(
        [PSCustomObject]@{
            Name = "start-agent"
            Cmd = "{0} nx-cloud start-agent" -f $npxCmd
            Description = "Start NX-Cloud agent"
            AlwaysRun = $true
        },
        [PSCustomObject]@{
            Name = "ci-run"
            Cmd = "{0} nx-cloud start-ci-run --stop-agents-after=`"build`" --agent-count={1}" -f $npxCmd, $agentCount
            Description = "Start CI Run"
            AlwaysRun = $true
        },
        [PSCustomObject]@{
            Name = "workspace"
            Cmd = "{0} nx-cloud record -- npx nx workspace-lint" -f $npxCmd
            Description = "Run workspace lint"
            AlwaysRun = $false
        },
        [PSCustomObject]@{
            Name = "format"
            Cmd = "{0} nx-cloud record -- npx nx format:check --base={1} --head={2}" -f $npxCmd, $baseSHA, $headSHA
            Description = "Check format"
            AlwaysRun = $false
        },
        [PSCustomObject]@{
            Name = "lint"
            Cmd = "{0} nx affected --base={1} --head={2} --target=lint --parallel={3}" -f $npxCmd, $baseSHA, $headSHA, $agentCount
            Description = "Run lint"
            AlwaysRun = $false
        },
        [PSCustomObject]@{
            Name = "test"
            Cmd = "{0} nx affected --base={1} --head={2} --target=test --parallel={3} --ci --code-coverage" -f $npxCmd, $baseSHA, $headSHA, $agentCount
            Description = "Run test"
            AlwaysRun = $false
        },
        [PSCustomObject]@{
            Name = "build"
            Cmd = "{0} nx affected --base={1} --head={2} --target=build --parallel={3}" -f $npxCmd, $baseSHA, $headSHA, $agentCount
            Description = "Run build"
            AlwaysRun = $false
        },
        [PSCustomObject]@{
            Name = "stop-agent"
            Cmd = "{0} nx-cloud stop-all-agents" -f $npxCmd
            Description = "Stop all Nx-Cloud agents"
            AlwaysRun = $true
        }
    )
}