
function Invoke-Terraform() {


    <#

    .SYNOPSIS
    A wrapper for the Terraform command which will invoke the different commands of
    Terraform as required

    .DESCRIPTION
    The Independent Runner uses Terraform to built up the resources that are required, primairly for ED Stacks,
    but can be for any Terraform defined infrastructure.

    It is a wrapper for the Terraform command and will generate the necessary command from the inputs that the
    cmdlet is given. The benefit of this cmdlet is that it reduces complexity as people do not need to know how
    to build up the Terraform command each time.

    .EXAMPLE
    Invoke-Terraform -init -arguments "false"

    Initialise the Terraform files with a fase backend. This is useful for validation.

    .EXAMPLE
    Invoke-Terraform -plan properties "-input=false", "-out=tf.plan"

    Plan the Terraform deployment using the files in the current directory. The properties that have been passed
    are appended directly to the end of the Terraform command. In this example no missing inputs are requests and
    the plan is written out to the `tf.plan` file.

    .EXAMPLE
    Invoke-Terraform -output -path src/terraform -yaml | Out-File tfoutput.yaml

    This command will get the outputs from the Terraform state and output them as Yaml format. It will only output
    the name and value of the output. This is then piped to Out-File which means that the data will be save to the
    named file for use with other commands.

    #>

    [CmdletBinding()]
    param (

        [string]
        # Path to the terraform files
        $path,

        [Parameter(
            ParameterSetName = "apply"
        )]
        [switch]
        # Initalise Terraform
        $apply,

        [Parameter(
            ParameterSetName = "custom"
        )]
        [switch]
        # Initalise Terraform
        $custom,

        [Parameter(
            ParameterSetName = "format"
        )]
        [switch]
        # Validate templates
        $format,

        [Parameter(
            ParameterSetName = "init"
        )]
        [switch]
        # Initalise Terraform
        $init,

        [Parameter(
            ParameterSetName = "plan"
        )]
        [switch]
        # Initalise Terraform
        $plan,

        [Parameter(
            ParameterSetName = "output"
        )]
        [switch]
        # Initalise Terraform
        $output,

        [Parameter(
            ParameterSetName = "output"
        )]
        [switch]
        # Allow the output of senstive values
        $sensitive,

        [Parameter(
            ParameterSetName = "output"
        )]
        [switch]
        # Set the output to be Yaml
        $yaml,

        [Parameter(
            ParameterSetName = "validate"
        )]
        [switch]
        # Perform validate check on templates
        $validate,

        [Parameter(
            ParameterSetName = "workspace"
        )]
        [switch]
        # Initalise Terraform
        $workspace,

        [string[]]
        [Alias("backend", "properties")]
        # Arguments to pass to the terraform command
        $arguments = $env:TF_BACKEND,

        [string]
        # Delimiter to use to split backend config that has been passed as one string
        $delimiter = ",",

        [string]
        # Version of Terraform to use
        # This will look for Terraform in the specified prefix
        # and will not use the Find-Command cmdlet
        $Version = $env:TF_VERSION,

        [string]
        # Path to the base directory for Terraform
        $Prefix,

        [Parameter(
            ParameterSetName = "output"
        )]
        $JsonDepth = 50
    )

    # set flag to state if the dir was changed
    $changedDir = $false

    # If the arguments is one element in the array split on the delimiter
    if ($arguments.Count -eq 1) {
        $arguments = $arguments -split $delimiter
    }

    # Check parameters exist for certain cmds
    if (@("init").Contains($PSCmdlet.ParameterSetName)) {
        # Check that some backend properties have been set
        # If they have not then raise an error
        # If they have then check to see if one argument has been raised and if it has split on the comma in case
        #   all the configs have been passed in as one string
        if ($arguments.Count -eq 0 -or ($arguments.Count -eq 1 -and [String]::IsNullOrEmpty($arguments[0]))) {
            Write-Error -Message "No properties have been specified for the backend" -ErrorAction Stop
            return
        }
    }

    if (@("plan", "apply").Contains($PSCmdlet.ParameterSetName)) {
        if ([String]::IsNullOrEmpty($path)) {
            Write-Error -Message "Path to the Terraform files or plan file must be supplied" -ErrorAction Stop
            return
        }

        if (!(Test-Path -Path $path)) {
            Write-Error -Message ("Specified path does not exist: {0}" -f $path) -ErrorAction Stop
            return
        }
    }

    # Ensure that the prefix path has been set if it is null
    # This is done so that the path delimiters are correctly added
    if ([String]::IsNullOrEmpty($Prefix)) {

        # determine the root
        $root = "/"
        if (Test-Path -Path env:\SystemDrive) {
            $root = $env:SystemDrive
        }

        $Prefix = [IO.Path]::Combine($root, "usr", "local", "terraform")
    }

    # Find the Terraform command to use
    if ([String]::IsNullOrEmpty($Version)) {
        $terraform = Find-Command -Name "terraform"
    }
    else {

        # A version has been specified so build up the path to the specified
        $terraform = [IO.Path]::Combine($Prefix, $Version, "bin", "terraform")

        # Check to see if the versioned Terraform exists
        if (!(Test-Path -Path $terraform)) {
            Write-Error -Message ("Specified Terraform version does not exist: {0}" -f $terraform) -ErrorAction Stop
            return
        }
    }

    # If a path has been specified and it is a directory
    # change to that path
    if (![string]::IsNullOrEmpty($path)) {

        # determine if the path is a file, and if so get the dir
        $dir = $path
        if (!((Get-Item -Path $dir) -is [System.IO.DirectoryInfo])) {
            $dir = Split-Path -Path $dir -Parent
        }

        Push-Location -Path $dir
        $changedDir = $true
    }

    Write-Information -MessageData ("Working directory: {0}" -f (Get-Location))

    # select operation to run based on the cmd
    switch ($PSCmdlet.ParameterSetName) {

        # Apply the infrastructure
        "apply" {
            $command = "{0} apply {1}" -f $terraform, $path
            Invoke-External -Command $command
        }

        # Run custom terraform command that is not supported by the function
        "custom" {
            $command = "{0} {1}" -f $terraform, ($arguments -join " ")
            Invoke-External -Command $command
        }

        # Initialise terraform
        "init" {

            # Iterate around the arguments
            $a = @()
            foreach ($arg in $arguments) {
                $a += "-backend-config='{0}'" -f $arg
            }

            # Build up the command to pass
            $command = "{0} init {1}" -f $terraform, ($a -join (" "))

            Invoke-External -Command $command
        }

        # Check format of templates
        "format" {

            $command = "{0} fmt -diff -check -recursive" -f $terraform

            Invoke-External -Command $command
        }

        # Plan the infrastrtcure
        "plan" {

            $command = "{0} plan {1}" -f $terraform, ($arguments -join " ")
            Invoke-External -Command $command

        }

        # Output information from the state
        # This will retrieve all the non-sensitive values, if these are required then
        # the -Sensitive switch must been specified
        "output" {

            # Run the command to get the state from terraform
            $command = "{0} output -json" -f $terraform
            $result = Invoke-External -Command $command

            if (![String]::IsNullOrEmpty($result)) {

                $data = $result | ConvertFrom-Json

                # iterate around the data and get the values for all the sensitive variables
                if ($sensitive) {
                    $data | Get-Member -MemberType NoteProperty | ForEach-Object {

                        $name = $_.Name

                        # if if the output is a sensitive value get the value using Terraform
                        if ($data.$name.sensitive) {
                            $value = Invoke-External -Command ("{0} output -raw {1}" -f $terraform, $name)

                            # set the value in the object
                            $data.$name.value = $value
                        }
                    }
                }

                # output the data as JSON unless Yaml has been specified
                if ($yaml) {

                    # As the aim of this is to get the name and value of the keys into a yaml
                    # file for ingestion by Inspec the name and value are the only things required
                    $yamldata = [Ordered] @{}
                    $sortedKeys = $data.PSObject.Properties | Sort-Object Name
                    foreach ($item in $sortedKeys) {
                        $yamldata[$item.Name] = $item.Value.Value
                    }

                    $yamldata | ConvertTo-Yaml
                }
                else {
                    $data | ConvertTo-Json -Depth $JsonDepth -Compress
                }
            }
        }

        # Valiate the templates
        "validate" {

            # Run the commands to perform a validation
            $commands = @()
            $commands += "{0} init -backend=false" -f $terraform
            $commands += "{0} validate" -f $terraform

            Invoke-External -Command $commands

            # After validation has run, delete the terraform dir and lock file
            # This is so that it does not interfere with the deployment of the infrastructure
            # when a valid backend is initialised
            Write-Information -MessageData "Removing Terraform init files for 'false' backend"
            $removals = @(
                ".terraform",
                ".terraform.lock.hcl"
            )
            foreach ($item in $removals) {
                if (Test-Path -Path $item) {
                    Remove-Item -Path $item -Recurse -Force
                }
            }
        }


        # Create or select the terraform workspace
        "workspace" {

            if ([String]::IsNullOrEmpty($arguments)) {
                Write-Error -Message "No workspace name specified to create or switch to."
            }
            else {
                Write-Information -MessageData ("Attempting to select or create workspace: {0}" -f $arguments[0])
                $command = "{0} workspace select -or-create=true {1}" -f $terraform, $arguments[0]
                Invoke-External -Command $command
            }
        }

    }

    if ($changedDir) {
        Pop-Location
    }
}
