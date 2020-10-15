<#
.SYNOPSIS
    Creates a pscustomobject to send to api
.DESCRIPTION
  Creates a pscustomobject to send to api. Uses Models in V1.JSON
  
.EXAMPLE
    PS C:\>  $body = New-AutotaskBody  -Resource CompanyModel
    Creates a new object in $Body with the companymodel, filled with expected content(e.g. int, string, boolean)

    PS C:\> $body = New-AutotaskBody  -Resource CompanyModel -NoContent
    Creates a new, empty object in $Body with the companymodel,
.INPUTS
    -NoContent Creates an empty object.
    -Resource tab completed model to use.
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function New-AutotaskBody {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)][switch]$NoContent
    )
    DynamicParam {
        $Script:PostPatchParameter
    }
    begin {
        if (!$Script:AutotaskAuthHeader -or !$Script:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $Headers = $Script:AutotaskAuthHeader
    }
    process {
        $ResourceURL = (($Script:Queries | Where-Object { $_.'Post' -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '' | Select-Object -first 1
        if ( !$ResourceURL ) {
            $ResourceURL = (($Script:Queries | Where-Object { $_.'Patch' -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '' | Select-Object -first 1
        }
        try {
            $resource = $PSBoundParameters.resource
            $ObjectTemplate = (Invoke-RestMethod -Uri "$($Script:AutotaskBaseURI)/$($resourceURL)/entityInformation/fields" -headers $Headers -Method Get).fields
            $UDFs = (Invoke-RestMethod -Uri "$($Script:AutotaskBaseURI)/$($resourceURL)/entityInformation/userdefinedfields" -headers $Headers -Method Get).fields | select-object name, value
            if (!$ObjectTemplate) { 
                Write-Warning "Could not retrieve example body for $($Resource)" 
            }
            else {
                if ($NoContent) { 
                    $ReturnedDef = [pscustomobject]
                    foreach ($prop in $ObjectTemplate.Name) { 
                        $ReturnedDef | Add-Member -NotePropertyName $prop -NotePropertyValue $null -Force
                    }
                    
                }
                if (!$NoContent) {
                    $ReturnedDef = [pscustomobject]
                    $ReturnedDef | Add-Member -NotePropertyName 'UserdefinedFields' -NotePropertyValue $UDFs -Force
                    foreach ($prop in $ObjectTemplate) { 
                        $ExpectedValue = if ($prop.picklistValues) { $prop.picklistValues | select-object Label, Value, IsActive } else { $($prop.datatype) }
                        $ReturnedDef | Add-Member -NotePropertyName $prop.name -NotePropertyValue $ExpectedValue -Force
                    }
                }
            }
            $Names = if ($UDFS) { $ObjectTemplate.name + "UserDefinedFields" } else { $ObjectTemplate.name }
            return $ReturnedDef | select-object $Names

        }
        catch {
            write-error "Getting object failed: $($_.Exception.Message)"
        }

    }
}