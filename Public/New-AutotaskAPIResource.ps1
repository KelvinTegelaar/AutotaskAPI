
<#
.SYNOPSIS
    Creates a new resource in the API to the supplied object.
.DESCRIPTION
 Creates resource in the API to the supplied object. Uses the Post method.  Null values will not be published.
.EXAMPLE
    PS C:\>  New-AutotaskAPIResource -resource companies -body $body
    Creates a new company using the body $body

.INPUTS
    -Resource: Which resource to find. Tab completion is available.
    -Body: Body created based on the model of the API.  Accepts pipeline input.
   
.OUTPUTS
    none
.NOTES
    So the API actually contains a method to get the fields for a body. Thinking of using that instead. 
    /atservicesrest/v1.0/EntityName/entityInformation/field
#>
function New-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Body
    )
    DynamicParam {
        $Script:POSTParameter
    }
    begin {
        if (!$Script:AutotaskAuthHeader -or !$Script:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Script:AutotaskAuthHeader
        $ResourceURL = (($Script:Queries | Where-Object { $_.'Post' -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '' | Select-Object -first 1
    }
    
    process {
        $SendingBody = $body | ConvertTo-Json -Depth 10
        try {
            Invoke-RestMethod -Uri "$($Script:AutotaskBaseURI)/$($resourceurl)"  -headers $Headers -Method post -Body $SendingBody
        }
        catch {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $streamReader.BaseStream.Position = 0
            if ($streamReader.ReadToEnd() -like '*{*') { $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json }
            $streamReader.Close()
            if ($ErrResp.errors) { 
                write-error "API Error: $($ErrResp.errors)" 
            }
            else {
                write-error "Connecting to the Autotask API failed. $($_.Exception.Message)"
            }
        }
    }
}