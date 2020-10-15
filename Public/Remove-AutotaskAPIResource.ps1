
<#
.SYNOPSIS
Deletes a resource in the API to the supplied object.
.DESCRIPTION
 Deletes a resource in the API to the supplied object. Uses the DELETE method. Each item in the object will be removed. Confirmation will be required.
.EXAMPLE
    PS C:\>  Remove-AutotaskAPIResource -resource Companies -ID 1234
    Deletes the company with ID 1234

.INPUTS
    -ID: ID of the resource you want to delete
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function Remove-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][boolean]$confirm,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$ID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]$ChildID
    )
    DynamicParam {
        $Script:DeleteParameter
    }
    begin {
        if (!$Script:AutotaskAuthHeader -or !$Script:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Script:AutotaskAuthHeader     
        $ResourceURL = (($Script:Queries | Where-Object { $_.'Delete' -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '/{PARENTID}' | Select-Object -first 1

    }
    
    
    process {
        if (!$ChildID -and $resource -like "*Child*") { Write-Warning "You must enter a Child ID to delete a Child resource." ; break }
        $resourceURL = $resourceURL -replace '{PARENTID}', $ID
        if ($childID) { $resourceURL = "$($resourceURL)" -replace '{ID}', $ChildID }
        if ($ID) { $resourceURL = "$($resourceURL)" -replace '{ID}', $ID }

        $SetURI = "$($Script:AutotaskBaseURI)/$($resourceURL)"
        try {
            if ($confirm -eq $true) {
                Invoke-RestMethod -Uri "$SetURI" -headers $Headers -Method Delete
            }
            else {
                write-host "You must set confirm to `$True to execute a deletion."
            }
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