<#
.SYNOPSIS
    Gets a specified resource in the API.
.DESCRIPTION
    Gets a specified resource in the API. retrieves data based either on ID or specific JSON query.
.EXAMPLE
    PS C:\>  Get-AutotaskAPIResource -resource Companies -id 1234 -verbose
    Gets the company with ID 1234

    Get-AutotaskAPIResource -resource Companies -SearchQuery "{filter='active -eq True'}"
    Gets all companies with the filter "Active = true"

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
        $ResourceURL = (($Script:Queries | Where-Object { $_.GET -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '/{PARENTID}' | Select-Object -first 1
        if ($SimpleSearch) {
            $SearchOps = $SimpleSearch -split ' '
            $SearchQuery = convertto-json @{
                filter = @(@{
                        field = $SearchOps[0]
                        op    = $SearchOps[1]
                        value = $SearchOps | select-object -skip 2
                    })
            } -Compress
            
        }
    }

    process {
        if ($resource -like "*child*" -and $SearchQuery) { 
            write-warning "You cannot perform a JSON Search on child items. To find child items, use the parent ID."
            break
        }
        if ($ID) {
            $ResourceURL = ("$($ResourceURL)" -replace '{parentid}', "$($ID)") 
        }
        if ($ChildID) { 
            $ResourceURL = ("$($ResourceURL)/$ChildID")
        }
        if ($SearchQuery) { 
            $ResourceURL = ("$($ResourceURL)/query?search=$SearchQuery" -replace '{PARENTID}', '')
        }
        $SetURI = "$($Script:AutotaskBaseURI)/$($ResourceURL)"
        try {
            do {
                $items = Invoke-RestMethod -Uri $SetURI -headers $Headers -Method Get
                $SetURI = $items.PageDetails.NextPageUrl
                #[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([datetime]::UtcNow, (get-timezone).id)
              
                if ($items.items) { 
                    foreach ($item in $items.items) {
                        foreach ($date in $item.psobject.Properties | Where-Object { $_.name -like '*date*' }) {
                         $ConvertedDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([datetime]$date.value, (get-timezone).id).ToString('yyyy-MM-ddTHH:mm:ss.fff')
                         $item.$($date.name) = $ConvertedDate 
                        }
                        $item
                    }
                }
                if ($items.item) {
                    foreach ($item in $items.item) {
                        foreach ($date in $item.psobject.Properties | Where-Object { $_.name -like '*date*' }) {
                         $ConvertedDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([datetime]$date.value, (get-timezone).id).ToString('yyyy-MM-ddTHH:mm:ss.fff')
                         $item.$($date.name) = $ConvertedDate 
                        }
                        $item
                    }
                    
                }  
            } while ($null -ne $SetURI)
        }
        catch {cd 
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
