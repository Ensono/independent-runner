
Describe "Get-PageImages" {

    BeforeAll {

        # Import the function under test
        . $PSScriptRoot/Get-PageImages.ps1
    }

    Context "page with unique images" {

        BeforeAll {

            $data = @"
<img src="images/image1.png" />
<img src="images/image2.png" />
<img src="images/image3.png" />
"@
        }

        it "will return an array of all the image paths" {

            $res = Get-PageImages -data $data

            $res.count | Should -Be 3
            $res[0].local | Should -Be "images/image1.png"
        }
    }

    Context "page with images using URL" {

        BeforeAll {

            $data = @"
<img src="https://www.example.com/images/image1.png" />
<img src="images/image2.png" />
<img src="images/image3.png" />
"@
        }

        it "will return an array of all the local image paths" {

            $res = Get-PageImages -data $data

            $res.count | Should -Be 2
            $res[0].local | Should -Be "images/image2.png"
        }    
    }

    Context "page with images using URL and duplicate images" {

        BeforeAll {

            $data = @"
<img src="https://www.example.com/images/image1.png" />
<img src="images/image2.png" />
<img src="images/image2.png" />
"@
        }

        it "will return an array of all the local image paths" {

            $res = Get-PageImages -data $data

            $res.count | Should -Be 1
            $res[0].local | Should -Be "images/image2.png"
        }    
    }    
}