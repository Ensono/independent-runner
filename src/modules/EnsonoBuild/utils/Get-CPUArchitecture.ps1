
function Get-CPUArchitecture() {

    [CmdletBinding()]
    param (

        [string]
        # Specify the operating system to use
        # If not specified the inbuilt IsWindws, IsMacOs, IsLinux vars will be uused
        $os
    )

    # Define variable to rteturn
    $arch = ""

    if ([string]::IsNullOrEmpty($os)) {

        # determine the operating system based on the magic variable
        if ($IsWindows) {
            $os = "windows"
        } elseif ($IsMacOS) {
            $os = "macos"
        } else {
            $os = "linux"
        }
    }

    # Use the $os variable to call necessary commands to get the architecture
    switch ($os) {
        "windows" {
            $arch = $env:PROCESSOR_ARCHITECTURE
        }
        default {
            $processor = Invoke-External "uname -m"
            switch ($processor) {
              "x86_64" {
                $arch = "amd64"
              }
              "arm64" {
                $arch = "arm64"
              }
            }
        }
    }

    return $arch.ToLower()
}
