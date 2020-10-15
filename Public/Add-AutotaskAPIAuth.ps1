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
    $Secret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
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
    }
    catch {
        write-host "Could not Retrieve baseuri. E-mail address might be incorrect. You can manually add the baseuri via the Add-AutotaskBaseURI cmdlet. $($_.Exception.Message)" -ForegroundColor red
    }

}