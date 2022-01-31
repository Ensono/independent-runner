Describe "Find-Projects" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/Find-Projects.ps1

        # Mock commands
        # - Get-ChildItem - mock to check that the parameters sent in are correct
        Mock -Command Get-ChildItem -MockWith { 

            return @{
                Path = $path
                Filter = $pattern
                Directory = $directory.IsPresent
                Recurse = $recurse
            }
        }
    }

    It "Calls Get-ChildItem for <path> with a pattern <pattern>" -ForEach @(
        @{ Pattern = "*.UnitTests.csproj"; Path = "/src"; Directory = $false }
        @{ Pattern = "*.UnitTests.csproj"; Path = "/src"; Directory = $true }
    ) {
        $result = Find-Projects -Pattern $Pattern -Path $Path -Directory:$Directory

        Should -Invoke -CommandName Get-ChildItem -Times 1

        $result.Path | Should -Be $Path
        $result.Filter | Should -Be $pattern
        $result.Directory | Should -Be $directory
    }
}