
function Publish-Confluence() {

    <#
    
    .SYNOPSIS
    Publish (create or update) a page in Confluence

    .DESCRIPTION
    This cmdlet takes the specified body and uploads it to Confluence. If the page already exists
    it will be updated

    #>

    [CmdletBinding()]
    param (
        [string]
        # Title of page being published
        $title,

        [string]
        # Space in which the page should belong
        $space,

        [string]
        # Name of the page that this page is a parent of
        $parent,

        [string]
        # Server to be used in the API call
        $server,

        [string]
        # Credentials to be used to access the API
        $credentials = $env:CONFLUENCE_CREDENTIALS,

        [string]
        # Body of the content that should be published
        $body,

        [string]
        # Checksum of the body to determine if a page needs to be updated
        # If passed to the function the checksum is not determined automatcially which
        # is useful if the content has been transformed from the original
        $checksum,

        [string]
        # Specify path for relative images in the body
        # This is used if there body is specified as a string, if it is a file then
        # the path is derived from the path to the file
        $path
    )

    # If the body is a file read in the contents
    $bodyPath = $path
    if (Test-Path -Path $body) {

        Write-Information -MessageData "File found for content, reading"

        if ([String]::IsNullOrEmpty($path)) {
            $bodyPath = Split-Path -Path $body -Parent
        }

        $body = Get-Content -Path $body -Raw
        
        # If the title has not been set use the filename as the title
        if ([String]::IsNullOrEmpty($title)) {
            $title = [System.IO.Path]::GetFileNameWithoutExtension($body)
        }
    }

    # Check that all the necessary parameters have been passed
    $result = Confirm-Parameters -list @("title", "space", "body", "server", "credentials")
    if (!$result) {
        return
    }    

    # See if page exists
    # Build up the path to path to use to see if the page exists
    $confluencePath = "/wiki/rest/api/content"

    # Get a checksum for the body, if it has not been specified
    if (!$checksum) {
        $checksum = Get-Checksum -Content $body
    }

    # Build the URL to use
    $url = Build-URI -Server $server -Path $confluencePath -query @{"title" = $title; "spaceKey" = $space; "expand" = "version"}

    # Call the API to get the information about the page
    $splat = @{
        url = $url
        credentials = $credentials
    }
    
    $pageDetails = Get-ConfluencePage @splat

    # If page does not exist then create it
    # this create the shell of the new page and returns the ID
    # the content will then be added as an update to the ID that is returned
    if ($pageDetails.Create) {

        # create the body object to creae the new page
        $pagebody = @{
            type = "page"
            title = $title
            space = @{
                key = $space
            }
            body = @{
                storage = @{
                    value = "Initial page created by the AmidoBuild PowerShell module. This will be updated shortly."
                    representation = "storage"
                }
            }
        }

        # if a parent has been specified get the ID of that page
        if (![String]::IsNullOrEmpty($parent)) {
            $url = Build-URI -Server $server -Path $confluencePath -query @{"title" = $parent; "spaceKey" = $space; "expand" = "version"}
            $pageDetails = Get-ConfluencePage -Url $url -Credential $credentials

            # If the parentId is not empty add it in as an ancestor for the page
            if (![string]::IsNullOrEmpty($pageDetails.ID)) {
                $pagebody.ancestors = @(@{id = $pageDetails.ID})
            }
        }

        # Create the initial page using the title and the spaceKey
        # The result of this will provide a pageId that can be used to update the content
        $splat = @{
            method = "POST"
            url = (Build-URI -Server $server -Path $confluencePath -query @{"expand" = "version"})
            body = (ConvertTo-Json -InputObject $pagebody -Depth 100)
            credentials = $credentials
        }

        $res = Invoke-API @splat

        if ($res -is [System.Exception]) {
            Stop-Task -Message $res.Message
        } else {
            $content = ConvertFrom-JSON -InputObject $res.Content
            $pageDetails.ID = $content.id
            $pageDetails.Version = $content.version.number
        }
    } else {

        # the page may need to be updated, but only do so if the checksums do not match
        if ($checksum -ieq $pageDetails.Checksum) {
            Write-Information -MessageData ("Page is up to date: '{0}' in '{1}' space" -f $title, $space)
            return
        }
    }

    # Get all the images in the HTML and determine which files need to be uploaded
    # Then modify the body so that the links are correct foreach uploaded image
    $pageImages = Get-PageImages -data $body

    foreach ($image in $pageImages) {

        # get the full path to the image
        $imgPath = [IO.Path]::Combine($bodyPath, $image.local)

        # only attempt to upload image and update body if it exists
        if (Test-Path -Path $imgPath) {
            Write-Information -MessageData ("Uploading image: {0}" -f $imgPath)

            # set the paramneters to send to the invoke-api to upload the image
            $splat = @{
                method = "POST"
                contenttype = 'multipart/form-data' #; boundary="{0}"' -f $delimiter
                formData = @{
                    file = Get-Item -Path $imgPath
                }
                headers = @{
                    "X-Atlassian-Token" = "nocheck"
                }
                url = (Build-URI -Server $server -Path ("{0}/{1}/child/attachment" -f $confluencePath, $pageDetails.ID))
                credentials = $credentials
            }

            $res = Invoke-API @splat

            # Replace the local img src to be the path for the attachment
            $image.remote = "/wiki/download/attachments/{0}/{1}" -f $pageDetails.ID, $imgItem.Name

            $body = $body -replace $image.local, $image.remote

        }
    }

    # prepare the body
    $preparedBody = @"
<ac:structured-macro ac:name="html" ac:schema-version="1">
    <ac:plain-text-body>
        <![CDATA[
            {0}
        ]]>
    </ac:plain-text-body>
</ac:structured-macro>
"@ -f $body

    # Using the ID of the page update the body
    # Update the splat of arguments to update the page with the necessary content
    $splat = @{
        method = "PUT"
        body = (ConvertTo-Json -InputObject @{
            id = $pageDetails.ID
            type = "page"
            title = $title
            space = @{
                key = $space
            }
            body = @{
                storage = @{
                    value = $preparedBody
                    representation = "storage"
                }
            }
            version = @{
                number = ($pageDetails.Version + 1)
            }
        })
        url = (Build-URI -Server $server -Path ("{0}/{1}" -f $confluencePath, $pageDetails.ID))
        credentials = $credentials
    }

    $res = Invoke-API @splat

    # Update the page properties so that the checksum of the data is set
    $splat = @{
        method = "PUT"
        url = (Build-URI -Server $server -Path ("{0}/{1}/property/checksum" -f $confluencePath, $pageDetails.ID))
        credentials = $credentials
        body = (ConvertTo-JSON -InputObject @{
            value = @(
                $checksum
            )
            version = @{
                number = $pageDetails.Version
            }
        })
    }

    $res = Invoke-API @splat

}