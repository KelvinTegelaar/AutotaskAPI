
<#
.SYNOPSIS
    Sets a resource in the API to the supplied object.
.DESCRIPTION
 Sets a resource in the API to the supplied object. Uses the Patch method. Each item in the object will be overwritten at the API side. Null values will overwrite with null values.
.EXAMPLE
    PS C:\>  Get-AutotaskAPIResource -resource Companies -ID 1234
    Finds the company with 1234 in the Autotask REST API.

    PS C:\>  Get-AutotaskAPIResource -resource Companies -SearchQuery={filter='active -eq true'}
    Finds all companies which are active.
.INPUTS
    -Resource: Which resource to find. Tab completion is available.
    -ID: ID of the resource you want to retrieve
    -SearchQuery: JSON Search filter.
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function Set-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'ParentID', Mandatory = $false)]
        [Parameter(ValueFromPipelineByPropertyName = $true)]$ID,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$body
    )
    DynamicParam {
        $Script:PatchParameter
    }
    begin {
        if (!$Script:AutotaskAuthHeader -or !$Script:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Script:AutotaskAuthHeader   
        $ResourceURL = (($Script:Queries | Where-Object { $_.'Patch' -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '' | Select-Object -first 1
  
    }
    
    process {
        try {
            $SendingBody = $PSBoundParameters.body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($Script:AutotaskBaseURI)/$($ResourceURL)" -headers $Headers -Body $SendingBody -Method Patch
        }
        catch {
            if ($psversiontable.psversion.major -lt 6) {
                $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $streamReader.BaseStream.Position = 0
                if ($streamReader.ReadToEnd() -like '*{*') { $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json }
                $streamReader.Close()
            }
            if ($ErrResp.errors) { 
                write-error "API Error: $($ErrResp.errors)" 
            }
            else {
                write-error "Connecting to the Autotask API failed. $($_.Exception.Message)"
            }
        }

    }
}