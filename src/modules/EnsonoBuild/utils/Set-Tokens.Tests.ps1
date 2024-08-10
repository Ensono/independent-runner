Describe "Set-Tokens" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Set-Tokens.ps1
    }

    It "will return a hashtable" {

        $tokens = Set-Tokens

        $tokens | Should -BeOfType [Hashtable]
    }

    It "will return all environment variables" {

        $tokens = Set-Tokens

        $envs = Get-ChildItem -Path env:*
        foreach ($env in $envs) {
            $tokens[$env.Name] | Should -Be $env.Value
        }
    }

    It "will return the version number" {

        $version = "1.0.0"

        $tokens = Set-Tokens -Version $version

        $tokens["version"] | Should -Be $version
    }
    It "will exclude environment variables" {

        $exclude = @("PATH", "PSModulePath")

        $tokens = Set-Tokens -Exclude $exclude

        $envs = Get-ChildItem -Path env:*
        foreach ($env in $envs) {
            if ($exclude -contains $env.Name) {
                $tokens[$env.Name] | Should -BeNullOrEmpty
            } else {
                $tokens[$env.Name] | Should -Be $env.Value
            }
        }
    }

    It "will convert the tokens to lowercase" {

        $tokens = Set-Tokens -Lower

        $envs = Get-ChildItem -Path env:*
        foreach ($env in $envs) {
            $tokens[$env.Name.ToLower()] | Should -Be $env.Value
        }
    }

    It "will add extra tokens" {

        $tokens = Set-Tokens -ExtraTokens @{"new" = "token"}

        $tokens["new"] | Should -Be "token"
    }

    It "will add extra tokens and lower the keys" {

        $tokens = Set-Tokens -ExtraTokens @{"New" = "token"} -Lower

        $tokens["new"] | Should -Be "token"
    }
}