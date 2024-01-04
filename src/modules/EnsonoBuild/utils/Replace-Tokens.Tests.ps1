Describe "Replace-Tokens" {

    BeforeAll {

        # Import the function being tested
        . $PSScriptRoot/Replace-Tokens.ps1


    }

    It "will replace a simple token" {

        $tokens = @{"name" = "Pester"}

        $data = Replace-Tokens -Tokens $tokens -Data "Hello my name is {{ name }}"

        $data | Should -BeExactly "Hello my name is Pester"
    }

    It "will replace a token with different padding" {

        $tokens = @{"name" = "Pester"}

        $data = Replace-Tokens -Tokens $tokens -Data "Hello my name is {{name  }}"

        $data | Should -BeExactly "Hello my name is Pester"
    }

    It "will replace with different delimiters" {

        $tokens = @{"name" = "Pester"}

        $data = Replace-Tokens -Tokens $tokens -Data "Hello my name is [[name  ,," -Delimiters @("[[", ",,")

        $data | Should -BeExactly "Hello my name is Pester"
    }

    It "will replace multiple tokens" {

        $tokens = @{"name" = "Pester"; "project" = "independent-runner"}

        $data = Replace-Tokens -Tokens $tokens -Data "{{ name }} is testing the {{ project }}"

        $data | Should -BeExactly "Pester is testing the independent-runner"
    }

    It "will replace automatic tokens" {

        $tokens = @{"name" = "Pester"}

        $data = Replace-Tokens -Tokens $tokens -Data "Hello my name is {{ name }} and the date is {{ date:%B %Y }}"

        $data | Should -BeExactly ("Hello my name is Pester and the date is {0}" -f (Get-Date -Uformat "%B %Y"))
    }

    It "will replace automatic tokens in a single string, e.g. a path" {

        $data = Replace-Tokens -Data "/app/content/{{ date:%Y }}/{{ date:%B }}/newsletter.adoc"

        $data | Should -BeExactly ("/app/content/{0}/{1}/newsletter.adoc" -f (Get-Date -Uformat "%Y"), (Get-Date -Uformat "%B"))
    }

}