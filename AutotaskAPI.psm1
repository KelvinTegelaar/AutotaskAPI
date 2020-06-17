<#
.SYNOPSIS
    Creates a new dynamic parameter for either the resource list or definitionslist inside of v1.json.
.DESCRIPTION
    Creates a new dynamic parameter for either the resource list or definitionslist inside of v1.json by opening the file, reading the contents and converting a custom object.
    this returns the used array. Definitons might be removed in future releases.
.EXAMPLE
    PS C:\> New-ResourceDynamicParameter -Parametertype "Resource"
    Creates
.INPUTS
    -Parametertype: Resource or Definitions
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function New-ResourceDynamicParameter
(
    [Parameter(Mandatory = $true)][string]$ParameterType
) {
    $ParameterName = "Resource"
    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $true
    $AttributeCollection.Add($ParameterAttribute)
    if (!$Script:Swagger) { $Script:Swagger = get-content "$($MyInvocation.MyCommand.Module.ModuleBase)\v1.json" -raw | ConvertFrom-Json }
    $Script:Queries = foreach ($Path in $Script:Swagger.paths.psobject.Properties) {
        [PSCustomObject]@{
            Name   = $path.Name
            Get    = $Path.value.get.tags
            Post   = $Path.value.post.tags
            Patch  = $Path.value.patch.tags
            Delete = $Path.value.delete.tags

        }
    }
    $ResourceList = foreach ($query in  $Queries | where-object { $null -ne $_."$ParameterType" }  ) {
        $resource = $query."$ParameterType" | Select-Object -last 1
        $resource
    }

    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ResourceList)
    $AttributeCollection.Add($ValidateSetAttribute)
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
    $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
    return $RuntimeParameterDictionary
}

<#
.SYNOPSIS
    Sets the current API URL
.DESCRIPTION
 Sets the API URL to the selected URL. URLs parameters can be tab-completed.
.EXAMPLE
    PS C:\> Add-AutotaskBaseURI -BaseURI https://webservices2.autotask.net/atservicesrest
    Sets the autotask BaseURI to https://webservices2.autotask.net/atservicesrest
.INPUTS
    -BaseURI: one of the following list:
        "https://webservices2.autotask.net/atservicesrest",
        "https://webservices11.autotask.net/atservicesrest",
        "https://webservices1.autotask.net/atservicesrest",
        "https://webservices17.autotask.net/atservicesrest",
        "https://webservices3.autotask.net/atservicesrest",
        "https://webservices14.autotask.net/atservicesrest",
        "https://webservices5.autotask.net/atservicesrest",
        "https://webservices15.autotask.net/atservicesrest",
        "https://webservices4.autotask.net/atservicesrest",
        "https://webservices16.autotask.net/atservicesrest",
        "https://webservices6.autotask.net/atservicesrest",
        "https://prde.autotask.net/atservicesrest",
        "https://pres.autotask.net/atservicesrest",
        "https://webservices18.autotask.net/atservicesrest",
        "https://webservices19.autotask.net/atservicesrest",
        "https://webservices12.autotask.net/atservicesrest"
.OUTPUTS
    none
.NOTES
    To-do: 
#>
function Add-AutotaskBaseURI (
    [ValidateSet(
        "https://webservices2.autotask.net/atservicesrest",
        "https://webservices11.autotask.net/atservicesrest",
        "https://webservices1.autotask.net/atservicesrest",
        "https://webservices17.autotask.net/atservicesrest",
        "https://webservices3.autotask.net/atservicesrest",
        "https://webservices14.autotask.net/atservicesrest",
        "https://webservices5.autotask.net/atservicesrest",
        "https://webservices15.autotask.net/atservicesrest",
        "https://webservices4.autotask.net/atservicesrest",
        "https://webservices16.autotask.net/atservicesrest",
        "https://webservices6.autotask.net/atservicesrest",
        "https://prde.autotask.net/atservicesrest",
        "https://pres.autotask.net/atservicesrest",
        "https://webservices18.autotask.net/atservicesrest",
        "https://webservices19.autotask.net/atservicesrest",
        "https://webservices12.autotask.net/atservicesrest")]
    [Parameter(Mandatory = $true)]$BaseURI
) {
    $Script:AutotaskBaseURI = "$($BaseURI)"
}
<#
.SYNOPSIS
    Sets the API authentication information.
.DESCRIPTION
 Sets the API Authentication headers, and automatically tries to find the correct URL based on your username.
.EXAMPLE
    PS C:\> Add-AutotaskAPIAuth -ApiIntegrationcode 'ABCDEFGH00100244MMEEE333' -credentials $Creds
    Creates header information for Autotask API.
.INPUTS
    -ApiIntegrationcode: The API Integration code found in Autotask
    -Credentials : The API user credentials
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function Add-AutotaskAPIAuth (
    [Parameter(Mandatory = $true)]$ApiIntegrationcode,
    [Parameter(Mandatory = $true)][PSCredential]$credentials
) {
    #We convert the securestring...back to a normal string :'( Why basic auth AT? why?!
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentials.Password)
    $Secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $Script:AutotaskAuthHeader = @{
        'ApiIntegrationcode' = $ApiIntegrationcode
        'UserName'           = $credentials.UserName
        'Secret'             = $secret
        'Content-Type'       = 'application/json'
    }
    write-host "Retrieving webservices URI based on username" -ForegroundColor Green
    try {
        $Version = (Invoke-RestMethod -Uri "https://webservices2.autotask.net/atservicesrest/versioninformation").apiversions | select-object -last 1
        $AutotaskBaseURI = Invoke-RestMethod -Uri "https://webservices2.autotask.net/atservicesrest/$($Version)/zoneInformation?user=$($Script:AutotaskAuthHeader.UserName)"
        write-host "Setting AutotaskBaseURI to $($AutotaskBaseURI.url) using version $Version" -ForegroundColor green
        Add-AutotaskBaseURI -BaseURI $AutotaskBaseURI.url.Trim('/')
        write-host "Setting API resource parameters. This may take a moment." -ForegroundColor green
        $Script:GetParameter = New-ResourceDynamicParameter -Parametertype "Get"
        $Script:PatchParameter = New-ResourceDynamicParameter -Parametertype "Patch"
        $Script:DeleteParameter = New-ResourceDynamicParameter -Parametertype "Delete"
        $Script:POSTParameter = New-ResourceDynamicParameter -Parametertype "Post"
    }
    catch {
        write-host "Could not Retrieve baseuri. E-mail address might be incorrect. You can manually add the baseuri via the Add-AutotaskBaseURI cmdlet. $($_.Exception.Message)" -ForegroundColor red
    }

}
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
                if ($items.items) { $items.items }
                if ($items.item) { $items.item }  
            } while ($null -ne $SetURI)
        }
        catch {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $streamReader.BaseStream.Position = 0
            $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
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
            $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
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
            $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
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
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $streamReader.BaseStream.Position = 0
            $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
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
        $Script:PatchParameter
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
        $ResourceURL = (($Script:Queries | Where-Object { $_.'Patch' -eq $Resource }).Name | Select-Object -first 1) -replace '/query', '' | Select-Object -first 1
        try {
            $resource = $PSBoundParameters.resource
            $ObjectTemplate = (Invoke-RestMethod -Uri "$($Script:AutotaskBaseURI)/$($resourceURL)/entityInformation/fields" -headers $Headers -Method Get).fields
            if (!$ObjectTemplate) { 
                Write-Warning "No object template found for this definition: $Definitions" 
            }
            else {
                if ($NoContent) { 
                    $ReturnedDef = [pscustomobject]
                    foreach ($prop in $ObjectTemplate.Name) { 
                        $ReturnedDef | Add-Member -NotePropertyName $prop -NotePropertyValue ' ' -Force
                    }
                    
                }
                if (!$NoContent) {
                    $ReturnedDef = [pscustomobject]
                    foreach ($prop in $ObjectTemplate) { 
                        $ExpectedValue = if ($prop.picklistValues) { $prop.picklistValues | select-object Label,Value,IsActive } else { $($prop.datatype) }
                        $ReturnedDef | Add-Member -NotePropertyName $prop.name -NotePropertyValue $ExpectedValue -Force
                    }
                }
            }
            return $ReturnedDef | select-object $ObjectTemplate.name

        }
        catch {
            write-error "Getting object failed: $($_.Exception.Message)"
        }

    }
}