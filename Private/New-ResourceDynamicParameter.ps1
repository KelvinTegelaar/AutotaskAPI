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
            Index  = $($path.name.split("/")[2])
            Name   = $($path.Name)
            Get    = $($Path.value.get.tags)
            Post   = $($Path.value.post.tags)
            Patch  = $($Path.value.patch.tags)
            Delete = $($Path.value.delete.tags)

        }
    }
    $ResourceList = $null
    foreach ( $ParameterTypeN in $ParameterType.Split( ' ' ) ) {
        $ResourceList += foreach ($query in  $Queries | where-object { $null -ne $_."$ParameterTypeN" }  ) {
            $resource = $query."$ParameterTypeN" | Select-Object -last 1
            $resource
        }
    }
    $ResourceList = $ResourceList | Sort-Object -Unique

    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ResourceList)
    $AttributeCollection.Add($ValidateSetAttribute)
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
    $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
    return $RuntimeParameterDictionary
}
