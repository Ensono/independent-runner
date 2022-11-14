function Invoke-YamlLint() {

    <#
    
    .SYNOPSIS
    Performs a Yaml Lint, using Python, against all YAML files in the path

    .DESCRIPTION
    Using Python, preferably in a container, this cmdlet will run the yamllint command
    against all of the yaml files in the specified directory.

    A configuration file for yaml lint is expected. By default this the cmdlet will look
    for the file called `yamllint.conf` in the directory from which the cmdlet was invoked.


    .NOTES
    Due to the license of yamllint, it needs to be installed by the cmdlet on each use. This
    is because the license of yamlint is GPL, which means that if we bundled it into a container
    *all* of our code would need to be distibuted under the GPL license. By installing it
    as and when we need it we do not need to do this.

    .EXAMPLE
    Invoke-YamlLint

    Perform a lint for all the yaml files in the current directory

    .EXAMPLE
    Invoke-Yamllint -basepath src/ -config config/config.yml

    Perform a yamllint on all yaml files in the `src/` directory and use a different
    configuration file

    #>

    [CmdletBinding()]
    param (
        [Alias("a")]
        [string]
        # Config File
        $ConfigFile = "yamllint.conf",

        [Alias("b")]
        [string]
        # Base path to search
        $BasePath = (Get-Location)
    )

    # Check that arguments have been supplied
    if ([string]::IsNullOrEmpty($ConfigFile)) {
        Write-Error -Message "-a, -configfile: Missing path to configuration file"
        return
    }

    if ([string]::IsNullOrEmpty($BasePath)) {
        Write-Error -Message "-b, -basepath: Missing base path to scan"
        return
    }

    # Check that the config file can be located
    if (!(Test-Path -Path $ConfigFile)) {
        Write-Error -Message ("ConfigFile cannot be located: {0}" -f $ConfigFile)
        return
    }

    # Check that the base path exists
    if (!(Test-Path -Path $BasePath)) {
        Write-Error -Message ("Specified base path does not exist: {0}" -f $BasePath)
        return
    }

    # Find the path to python
    # Look for python3, if that fails look for python but then check the version
    $python = Find-Command -Name "python3"
    if ([string]::IsNullOrEmpty($python)) {
        Write-Debug -Message "Cannot find 'python3'. Looking for 'python' and checking version"

        $python = Find-Command -Name "python"

        if ([string]::IsNullOrEmpty($python)) {
            Write-Error -Message "Python3 cannot be found, please ensure it is installed"  -ErrorAction Stop
        }

        # Check the version of pythong
        $cmd = "{0} -V" -f $python
        $result = Invoke-External -Command $cmd

        if (![string]::IsNullOrEmpty($result) -and !$result.StartsWith("Python 3")) {
            Write-Error -Message "Python3 cannot be found, please ensure it is installed"  -ErrorAction Stop
        }
    }

    # Ensure that yamllint is installed and if not install it
    # This is done so that we are no shipping YamlLint in the container we use to run taskctl
    # YamlLint has a GPL 3 licence which means that if we are shipping the code we have to have
    # all of our code be licenced under GPL 3. By installing when we need it we are not shipping source code
    $pip = Find-Command -Name "pip"
    $cmd = "{0} freeze" -f $pip
    $result = Invoke-External -Command $cmd
    $yamllint = $result | Where-Object { ![String]::IsNullOrEmpty($_) -and $_.StartsWith("yamllint") }
    if ([string]::IsNullOrEmpty($yamllint)) {

        Write-Information -MessageData "Installing Python package: yamllint"

        # The package is not installed so install it now
        $cmd = "{0} install yamllint" -f $pip
        Invoke-External -Command $cmd
    }

    # Create the command that needs to be run to perform the lint function
    $cmd = "{0} -m yamllint -sc {1} {2} {1}" -f $python, $ConfigFile, $BasePath
    Invoke-External -Command $cmd

}