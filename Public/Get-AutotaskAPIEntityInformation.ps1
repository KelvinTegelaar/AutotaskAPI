<#
.SYNOPSIS
    Gets a specified entity in the API.
.DESCRIPTION
    Gets a specified resource in the API. retrieves data based either on ID or specific JSON query.
.EXAMPLE
    PS C:\>  Get-AutotaskAPIEntityInformation
    Gets all the entity information for tickets as one large array of objects, that then you can parse through in powershell on your own.

    PS C:\> Get-AutotaskAPIEntityInformation -entity "Tickets" -field "status" -value 29
    Gets the ticket status 29 and returns that as a simple powershell object we can pull the label from.

    PS C:\> Get-AutotaskAPIEntityInformation -entity "Tickets" -field "source"
    Gets all the entity information for ticket sources and returns it as an array of objects we can search through.

    PS C:\> Get-AutotaskAPIEntityInformation -entity "Companies" -field "classification" -value 17
    Gets the object for company classification value 17


.INPUTS
    -Entity: What Entity are we looking at? Companies, Tickets, or Contacts?
    -SearchQuery: JSON search filter.
    -SimpleSearch: a simple search filter, e.g. name eq Lime

.OUTPUTS
    none
.NOTES
    TODO: I think my code needs a little cleaning up and tweaking from someone who REALLY understands powershell, and maybe this shouldn't be doing returns in the middle?
#>
function Get-AutotaskAPIEntityInformation {
  [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'field', Mandatory = $true)]
        [String]$entity,
        [Parameter(ParameterSetName = 'field', Mandatory = $false)]
        [String]$field,
        [Parameter(ParameterSetName = 'field', Mandatory = $false)]
        [String]$value
    )


    begin {
        if (!$Script:AutotaskAuthHeader -or !$Script:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets"
            break
        }
        $field = $PSBoundParameters.field
        $headers = $Script:AutotaskAuthHeader
    }
    process {

        $SetURI = "$($Script:AutotaskBaseURI)/v1.0/$($entity)/entityinformation/fields/"
        #$SetURI = "https://webservices15.autotask.net/atservicesrest/v1.0/Tickets/entityinformation/fields/"
        try {
              $items = Invoke-RestMethod -Uri $SetURI -headers $Headers -Method Get

              #dealing with what flags I have.  I can't have values without fields, so that edits the return before the return of fields,
              #but even if both are false I want to return the whole array so we can just parse in powershell once we have the big object
              #flags are just for making this a little nicer.

              if($field){
                $target_field = ($items.fields | where name -eq "$field").picklistValues
                if($value){
                  $target_value = $target_field | where value -eq $value
                  return $target_value
                }
                return $target_field
              }
              return $items
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
