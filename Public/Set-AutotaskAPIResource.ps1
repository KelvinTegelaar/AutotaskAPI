
<#
.SYNOPSIS
    Sets a resource in the API to the supplied object.
.DESCRIPTION
 Sets a resource in the API to the supplied object. Uses the Patch method. Each item in the object will be overwritten at the API side. Null values will overwrite with null values.
.EXAMPLE
    PS C:\>  Set-AutotaskAPIResource -resource Companies -ID 1234 -Body $body
    Updates the company with ID 1234 in the Autotask REST API, changing any parameters in $body.

    PS C:\>  $TicketList = Get-AutotaskAPIResource -Resource Tickets -SimpleSearch "title eq Nope!"
    PS C:\>  $ticketlist | ForEach-Object { $_.status = "12" }
    PS C:\>  $ticketlist | Set-AutotaskAPIResource -Resource Tickets
    Closes all tickets with the subject "Nope!".

    Get-AutotaskAPIResource -Resource Companies -SimpleSearch 'Isactive eq true' | ForEach-Object {$_.Webaddress = "www.google.com"; $_} | Set-AutotaskAPIResource -Resource companies
    A one-liner to change all companies webaddresses to "google.com".

.INPUTS
    -Resource: Which resource to find. Tab completion is available.
    -ID: ID of the resource you want to update. Can be passed as a property on the pipeline.
    -ParentID: For use with 'Child' endpoints, the ID of the parent you are updating.
    -Body: A PS object containing all of the parameters you want to update. Can be passed by pipeline.
    
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function Set-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'ParentID', Mandatory = $false)][String]$ParentId,
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

        if ($resource -like "*child*" ) {
            if ( !$ParentId ) {
                Write-Warning "You must specify a parentId when settings a child resource" 
                break 
            }
            $ResourceURL = $resourceURL -replace '{parentId}', $ParentId
        }
    }
    
    process {
        $MyBody = New-Object -TypeName PSObject
        $PSBoundParameters.body.PSObject.properties | Where-Object {$null -ne $_.Value} | ForEach-Object {Add-Member -InputObject $MyBody -NotePropertyMembers @{$_.Name=$_.Value}}
        
        if ($ID) {
          $MyBody | Add-Member -NotePropertyMembers @{id=$ID} -Force
        }
        
        if ($null -eq $MyBody.ID) {
          Write-Warning "Body must contain an ID." 
          break
        }
        
        try {
            # Iterating through the property names above produces an array of n MyBody objects, all the same,
            # where n is the number of non-null properties.  Grab the first one.
            $SendingBody = $MyBody[0] | ConvertTo-Json -Depth 10
            $EncodedSendingBody = [System.Text.Encoding]::UTF8.GetBytes($SendingBody)
            Invoke-RestMethod -Uri "$($Script:AutotaskBaseURI)/$($ResourceURL)" -headers $Headers -Body $EncodedSendingBody -Method Patch
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
