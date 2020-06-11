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
    $ParameterName = "$($ParameterType)"
    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $true
    $AttributeCollection.Add($ParameterAttribute)
    
    $Swagger = get-content "$($PSScriptRoot)\v1.json" -raw | ConvertFrom-Json
    $Queries = foreach ($Path in $swagger.paths.psobject.Properties) {
        [PSCustomObject]@{
            Name  = $path.Name
            Value = $path.value
        }
    }
    if ($($ParameterType) -eq "Resource") {
        $ResourceList = foreach ($query in  $Queries | where-object { $_.name -like "*{id}*" }  ) {
            $resource = ($query.name -split "/")[2]
            $resource
        }
    }
    
    if ($($ParameterType) -eq "Definitions") {
        $ResourceList = foreach ($Path in $swagger.definitions.psobject.Properties) {
            $path.Name
        }
    
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
    Function might be changed at release of new API.
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
    $Global:AutotaskBaseURI = "$($BaseURI)/v1.0"
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
    $Global:AutotaskAuthHeader = @{
        'ApiIntegrationcode' = $ApiIntegrationcode
        'UserName'           = $credentials.UserName
        'Secret'             = $secret
        'ContentType'        = 'application/json'
    }
    write-host "Retrieving webservices URI based on username" -ForegroundColor Green
    try {
        $AutotaskBaseURI = Invoke-RestMethod -Uri "https://webservices2.autotask.net/atservicesrest/v1.0/zoneInformation?user=$($Global:AutotaskAuthHeader.UserName)"
        #Little hacky, but rest api current returns double slashes.
        $AutotaskBaseURI.url = $AutotaskBaseURI.url -replace "//A", "/A"
        Add-AutotaskBaseURI -BaseURI $AutotaskBaseURI.url
        write-host "Set AutotaskBaseURI to $($AutotaskBaseURI.url) " -ForegroundColor green
    }
    catch {
        write-host "Could not automatically determine webservices URI. Please run Add-AutotaskBaseURI" -ForegroundColor red
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
   
.OUTPUTS
    none
.NOTES
    Function might be changed at release of new API.
#>
function Get-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = 'ID', Mandatory = $true, ValueFromPipelineByPropertyName = $true)][String]$ID,
        [Parameter(ParameterSetName = 'SearchQuery', Mandatory = $true)][String]$SearchQuery
    )
    DynamicParam {
        New-ResourceDynamicParameter -ParameterType resource
    }
    begin {
        if (!$Global:AutotaskAuthHeader -or !$Global:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Global:AutotaskAuthHeader

    }
    process {
        
        if ($ID) { $SetURI = "$($Global:AutotaskBaseURI)/$($resource)/$ID" }
        if ($SearchQuery) { $SetURI = "$($Global:AutotaskBaseURI)/$($resource)/query?search=$SearchQuery" }
        try {
            Invoke-RestMethod -Uri $SetURI -headers $Headers -Method Get
        }
        catch {
            write-error "Connecting to the Autotask API failed. $($_.Exception.Message)"
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
    Function might be changed at release of new API.
#>
function New-AutotaskAPIResource {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$Body
    )
    DynamicParam {
        New-ResourceDynamicParameter -ParameterType Resource
    }
    begin {
        if (!$Global:AutotaskAuthHeader -or !$Global:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Global:AutotaskAuthHeader

    }
    
    process {
        $SendingBody = $body | ConvertTo-Json -Depth 10
        try {
            Invoke-RestMethod -Uri "$($Global:AutotaskBaseURI)/$($resource)"  -headers $Headers -Method post -Body $SendingBody
        }
        catch {
            write-error "Connecting to the Autotask API failed. $($_.Exception.Message)"
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
        [Parameter(Mandatory = $true)]$Body,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$ID
    )
    DynamicParam {
        New-ResourceDynamicParameter -ParameterType 'Resource'
    }
    begin {
        if (!$Global:AutotaskAuthHeader -or !$Global:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $resource = $PSBoundParameters.resource
        $headers = $Global:AutotaskAuthHeader     
        $SendingBody = $body | ConvertTo-Json -Depth 10
    }
    
    process {
        try {
            Invoke-RestMethod -Uri "$($Global:AutotaskBaseURI)/$($resource)/$ID" -headers $Headers -Method Patch -Body $SendingBody
        }
        catch {
            write-error "Connecting to the Autotask API failed. $($_.Exception.Message)"
        }

    }
}

<#
.SYNOPSIS
    Creates a pscustomobject to send to api
.DESCRIPTION
  Creates a pscustomobject to send to api. Uses Models in V1.JSON
  
.EXAMPLE
    PS C:\>  $body = New-AutotaskBody  -Definitions CompanyModel
    Creates a new object in $Body with the companymodel, filled with expected content(e.g. int, string, boolean)

    PS C:\> $body = New-AutotaskBody  -Definitions CompanyModel -NoContent
    Creates a new, empty object in $Body with the companymodel,
.INPUTS
    -NoContent Creates and empty object.
    -Definitions tab completed model to use.
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
        New-ResourceDynamicParameter -ParameterType "Definitions"
    }
    begin {
        if (!$Global:AutotaskAuthHeader -or !$Global:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $Definitions = $PSBoundParameters.Definitions
    }
    process {
        try {
            $Swagger = get-content "$($PSScriptRoot)\v1.json" -raw | ConvertFrom-Json
            $DefinitionsList = foreach ($Path in $swagger.definitions.psobject.Properties) {
                [PSCustomObject]@{
                    Name  = $path.Name
                    Value = $path.value
                }
              
            }
            $ObjectTemplate = ($DefinitionsList | Where-Object { $_.Name -eq $Definitions }).value.Properties
            if (!$ObjectTemplate) { 
                Write-Warning "No object template found for this definition: $Definitions" 
            }
            else {
                if ($NoContent) { 
                    foreach ($prop in $ObjectTemplate.psobject.Properties.Name) { 
                        $ObjectTemplate.$prop = $null 
                    }
                    $ReturnedDef = $ObjectTemplate 
                }
                if (!$NoContent) {
                    $ReturnedDef = $ObjectTemplate
                }
            }
            return $ReturnedDef

        }
        catch {
            write-error "Getting object failed: $($_.Exception.Message)"
        }

    }
}