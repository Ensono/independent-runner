Describe "ConvertTo-MDX" {

    BeforeAll {

        # Include function under test
        . $PSScriptRoot/ConvertTo-MDX.ps1

        # Include depdendent functions
        . $PSScriptRoot/Confirm-Parameters.ps1

        # Mock commands that need to checked for invocation
        Mock -CommandName Write-Error -MockWith {}
    }

    Context "Inavlid parameters" {

        It "will error if path and destination is not specified" {
            $result = ConvertTo-MDX

            $result | Should -Be $false
            
            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will error if path is not specified" {
            $result = ConvertTo-MDX -Destination "dest"

            $result | Should -Be $false
            
            Should -Invoke -CommandName Write-Error -Times 1
        }

        It "will error if destination is not specified" {
            $result = ConvertTo-MDX -Path "dest"

            $result | Should -Be $false
            
            Should -Invoke -CommandName Write-Error -Times 1
        }    

        it "will error if the MD file does not exist" {

            $result = ConvertTo-MDX -Path "index.md" -Destination "index.mdx"

            $result | Should -Be $false
            
            Should -Invoke -CommandName Write-Error -Times 1
        }
    }

    Context "Parse an MD file" {

        BeforeEach {
            # Create a folder to use for each test
            $testFolder = (New-Item 'TestDrive:\folder' -ItemType Directory).FullName
        }

        AfterEach {
            Remove-Item -Path $testFolder -Recurse -Force | Out-Null
        }

        It "will generate an MDX file from a MD file that has been specified" {

            # Create a file with some Markdown in it
            $mdFile = [IO.Path]::Combine($testFolder, "index.md")
            $mdxFile = [IO.Path]::Combine($testFolder, "index.mdx")
            Add-Content -Path $mdFile -Value '<table class="mytable">'

            ConvertTo-MDX -Path $mdFile -Destination $mdxFile

            Test-Path -Path $mdxFile | Should -Be $true
            Get-Content -Path $mdxFile -Raw | Should -BeLike '*table className="mytable"*'
        }
    }
}
