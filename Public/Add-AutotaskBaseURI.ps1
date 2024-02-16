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
        "https://webservices12.autotask.net/atservicesrest",
        "https://webservices24.autotask.net/atservicesrest"
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
        "https://webservices12.autotask.net/atservicesrest",
        "https://webservices24.autotask.net/atservicesrest")]
    [Parameter(Mandatory = $true)]$BaseURI
) {
    $Script:AutotaskBaseURI = "$($BaseURI)"
    write-host "Setting API resource parameters. This may take a moment." -ForegroundColor green
    $Script:GetParameter = New-ResourceDynamicParameter -Parametertype "Get"
    $Script:PatchParameter = New-ResourceDynamicParameter -Parametertype "Patch"
    $Script:DeleteParameter = New-ResourceDynamicParameter -Parametertype "Delete"
    $Script:POSTParameter = New-ResourceDynamicParameter -Parametertype "Post"
    $Script:PostPatchParameter = New-ResourceDynamicParameter -Parametertype "Post Patch"
}