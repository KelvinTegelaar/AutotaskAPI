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

function Add-AutotaskAPIAuth (
    [Parameter(Mandatory = $true)]$ApiIntegrationcode,
    [Parameter(Mandatory = $true)][PSCredential]$credentials
) {
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