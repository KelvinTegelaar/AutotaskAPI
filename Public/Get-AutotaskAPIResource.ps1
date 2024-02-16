<#
.SYNOPSIS
    Gets a specified resource in the API.
.DESCRIPTION
    Gets a specified resource in the API. retrieves data based either on ID or specific JSON query.
.EXAMPLE
    PS C:\>  Get-AutotaskAPIResource -resource Companies -id 1234 -verbose
    Gets the company with ID 1234

    PS C:\>  Get-AutotaskAPIResource -Resource Companies -SearchQuery '{"filter":[{"op":"eq","field":"isactive","value":"true"}]}
    Gets all companies with the filter "Active = true"

    PS C:\>  Get-AutotaskAPIResource -resource Companies -SimpleSearch "isactive eq $true"
    Gets all companies with the filter "Active = true"

    PS C:\>  Get-AutotaskAPIResource -resource Companies -SimpleSearch "companyname beginswith A"
    Gets all companies that start with the letter A

    See https://github.com/KelvinTegelaar/AutotaskAPI/blob/master/README.md for more examples.
    
.INPUTS
    -ID: Search by Autotask ID. Accept pipeline input.
    -SearchQuery: JSON search filter.
    -SimpleSearch: a simple search filter, e.g. name eq Lime
   
.OUTPUTS
    none
.NOTES
    TODO: Turns out some items have child URLS. figure that out.
#>
function Get-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'ID', Mandatory = $true)]
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$ID,
        [Parameter(ParameterSetName = 'ID', Mandatory = $false)]
        [String]$ChildID,
        [Parameter(ParameterSetName = 'SearchQuery', Mandatory = $true)]
        [String]$SearchQuery,
        [Parameter(ParameterSetName = 'SimpleSearch', Mandatory = $true)]
        [String]$SimpleSearch
    )
    DynamicParam {
        $Script:GetParameter
    }
    begin {
        if (!$Script:AutotaskAuthHeader -or !$Script:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Script:AutotaskAuthHeader
        $Script:Index = $Script:Queries | Group-Object Index -AsHashTable -AsString
        $ResourceURL = @(($Script:Index[$resource] | Where-Object { $_.Get -eq $resource }))[0]
        $ResourceURL.name = $ResourceURL.name.replace("/query", "/{PARENTID}") 
        if ($SimpleSearch) {
            $SearchOps = $SimpleSearch -split ' '
            $SearchQuery = ConvertTo-Json @{
                filter = @(@{
                        field = $SearchOps[0]
                        op    = $SearchOps[1]
                        value = $SearchOps | Select-Object -Skip 2
                    })
            } -Compress
            
        }
    }

    process {
        if ($resource -like "*child*" -and $SearchQuery) { 
            Write-Warning "You cannot perform a JSON Search on child items. To find child items, use the parent ID."
            break
        }
        if ($ID) {
            $ResourceURL = ("$($ResourceURL.name)" -replace '{parentid}', "$($ID)") 
        }
        if ($ChildID) { 
            $ResourceURL = ("$($ResourceURL)/$ChildID")
        }
        if ($SearchQuery) { 
            $ResourceURL = ("$($ResourceURL.name)/query?search=$SearchQuery" -replace '{PARENTID}', '')
        }
        $SetURI = "$($Script:AutotaskBaseURI)/$($ResourceURL)"
        try {
            do {
                $items = Invoke-RestMethod -Uri $SetURI -Headers $Headers -Method Get
                $SetURI = $items.PageDetails.NextPageUrl
                #[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([datetime]::UtcNow, (get-timezone).id)
            
                if ($items.items) { 
                    foreach ($item in $items.items) {

                        $item
                    }
                }
                if ($items.item) {
                    foreach ($item in $items.item) {

                        $item
                    }
                    
                }  
            } while ($null -ne $SetURI)
        }
        catch {
            if ($psversiontable.psversion.major -lt 6) {
                $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $streamReader.BaseStream.Position = 0
                if ($streamReader.ReadToEnd() -like '*{*') { $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json }
                $streamReader.Close()
            }
            if ($ErrResp.errors) { 
                Write-Error "API Error: $($ErrResp.errors)" 
            }
            else {
                Write-Error "Connecting to the Autotask API failed. $($_.Exception.Message)"
            }
        }

    }
}
