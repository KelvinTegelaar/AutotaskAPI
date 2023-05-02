# AutotaskAPI PowerShell Module

This is a PowerShell wrapper for the new Autotask REST API, released by Datto in version 2020.2. This API is a replacement of the SOAP API. The REST API is faster and easier to develop for, than the SOAP API. If you need to use the SOAP API for whatever reason, then check out the project [Autotask by ecitsolutions](https://github.com/ecitsolutions/Autotask). This is by far the best wrapper for the SOAP API.

For more information, check out the [Datto/Autotask](https://www.datto.com/integrations/lime-networks-b-v-cyberdrain-com) page about this module too.

Some users wanted a benchmark of the new API. The following results have been performed on the sandbox of Autotask, to which I have a RTT of about 150-180MS.

Getting 721 tickets based on a title filter: "Title eq hello!"

REST: 9.23 seconds
SOAP: 134,14 seconds

Getting all active companies in sandbox (1000 companies)

REST: 9,5 seconds
SOAP: 86,6 seconds

## Installation instructions

This module has been published to the PowerShell Gallery. Use the following command to install:  

```powershell
Install-Module AutotaskAPI
```

## Usage

### Authentication

To get items using the Autotask API you'll first have to add the authentication headers using the `Add-AutotaskAPIAuth` function. Example:

```powershell
$Creds = Get-Credential

Add-AutotaskAPIAuth -ApiIntegrationCode 'ABCDEFGH00100244MMEEE333' -credentials $Creds
```

When the command runs, You will be asked for credentials. Using these, we will try to decide the correct webservice URL for your zone based on the e-mail address. If this fails you must manually set the webservice URL.

```powershell
Add-AutotaskBaseURI -BaseURI https://webservices1.autotask.net/atservicesrest
```

The Base URI value has tab completion to help you find the correct one easily. For more information about zones consult the [Autotask API Docs about zones](https://www.autotask.net/help/developerhelp/Content/APIs/General/API_Zones.htm) or [Autotask User Login help](https://www.autotask.net/help/Content/2_Getting_Started/LogIntoAutotask.htm?Highlight=hosted)

### Pagination

The Powershell Module has automatic pagination, meaning if you are retrieving more than 500 records from the API, it will automatically fetch all items.

### Filters

To find resources using the API, execute the `Get-AutotaskAPIResource` function. For the `Get-AutotaskAPIResource` function, you will need either the ID of the resource you want to retrieve, or the JSON SearchQuery you want to execute.

With this Module, you can either use native JSON filters that are sent to the API. In this scenario use the *-SearchQuery* option. This allows for complex filters with AND / OR dependencies:

- all companies that are active
- all companies that are active and type customer
- all companies that are ((active and with (type customer or partner) and have UDF 'cool company' set to 'YES') or are located in countryId 42 and managed by Jim)

If you don't need more than one filter set, you can use *-SimpleSearch* instead. Simple search will build a single JSON statement for you. Simple filters doesn't support  multiple statements and is therefor limited to one single filter (e.g. all companies with "isactive = true").

You can find examples for filters below. In addition the [Autotask documentation about Basic Queries](https://www.autotask.net/help/developerhelp/Content/APIs/REST/API_Calls/REST_Basic_Query_Calls.htm) contains a documentation of all keywords and further examples, that might help.

## Examples

### GET/Read data from Autotask

To find the company with ID 12345:

```powershell
Get-AutotaskAPIResource -Resource Companies -ID 12345
```

To get all companies that are Active with SearchQuery:

```powershell
Get-AutotaskAPIResource -Resource Companies -SearchQuery '{"filter":[{"op":"eq","field":"isactive","value":"true"}]}'
```

To get all companies that are Active with SimpleSearch:

```powershell
Get-AutotaskAPIResource -Resource Companies -SimpleSearch "isactive eq $true"
```

To get all companies that start with the letter A:

```powershell
Get-AutotaskAPIResource -Resource Companies -SimpleSearch "companyname beginswith A"
```

To get all child alerts for company 1234

```powershell
Get-AutotaskAPIResource -Resource CompanyAlertsChild -ID 1234 -verbose
```

To get only child 7 in company id 1234

```powershell
Get-AutotaskAPIResource -Resource CompanyAlertsChild -ID 29683578 -ChildID 7
```

### Combine Data with other Modules

It's also possible to use this module to combine stuff, for example to create a Microsoft Team for each open project:

```powershell
Import-Module MicrosoftTeams
Connect-MicrosoftTeams
Add-AutotaskAPIAuth
$Projects = Get-AutotaskAPIResource -Resource Projects -SimpleSearch 'status ne completed'
foreach ($Project in $Projects) {
    $NewTeam = New-Team -MailNickname "$($project.projectnumber)" -DisplayName "$($project.projectnumber) - $($project.name)" -Visibility "private"
    $TeamLeadEmail = (Get-AutotaskAPIResource -Resource resources -ID $($project.projectLeadResourceID)).email
    Add-TeamUser -GroupId $NewTeam.GroupId -User $TeamLeadEmail
}
```

### POST/Create data in Autotask

To create a new company, we can either make the entire body ourselves, or use the `New-AutotaskBody` function.

```powershell
$Body = New-AutotaskBody -Resource Companies
```

This creates a body for the model Company. Definitions can be tab-completed. The body will contain all expected values. If you want an empty body instead, use:

```powershell
$Body = New-AutotaskBody -Resource Companies -NoContent
```

If you only want to know what picklist options are available, for a specific resource use the following:

```powershell
(New-AutotaskBody -Resource Tickets -NoContent).status
```

This will print a list with all possible options.

After setting the values for the body you want, execute:

```powershell
New-AutotaskAPIResource -Resource Companies -Body $body
```

### PATCH/Update data in Autotask

To set existing companies, use the `Set-AutotaskAPIResource` function. This uses the Patch method so remember to remove any properties you do not want updated.

```powershell
Set-AutotaskAPIResource -Body $body
```

Both `Set-AutotaskAPIResource` and `New-AutotaskAPIResource` accept pipeline input, for example, to change a title of a specific ticket:

```powershell
$Ticket = Get-AutotaskAPIResource -Resource tickets -SimpleSearch "id eq 12345"
```

Or to close all tickets with the subject "Nope!"

```powershell
$TicketList = Get-AutotaskAPIResource -Resource Tickets -SimpleSearch "title eq Nope!"
$TicketList | ForEach-Object { $_.status = "12" }
$TicketList | Set-AutotaskAPIResource -Resource Tickets
```

Or a one-liner to change all companies webaddresses to "google.com"

```powershell
Get-AutotaskAPIResource -Resource Companies -SimpleSearch 'Isactive eq true' | ForEach-Object {$_.Webaddress = "www.google.com"; $_} | Set-AutotaskAPIResource -Resource Companies
```

### DELETE/Remove data from API

> **WARNING**
> You can and will delete actually data from your PSA instance. There is no recycle bin or restore function, if you defined faulty filters or used wrong IDs. Therefore all examples are permitted in execution by using -Confirm $false. If you copy and paste the lines, they won't be executed.

If Confirm is not set, the Module won't delete data from Autotask.

Delete the company with ID 1234. Each item in the object will be removed. Confirmation will be required.

```powershell
Remove-AutotaskAPIResource -Resource Companies -ID 1234 -Confirm $false
```

`Remove-AutotaskAPIResource` also accept pipeline input.

```powershell
Get-AutotaskAPIResource -Resource Companies -SimpleSearch 'Isactive eq true' | Remove-AutotaskAPIResource -Confirm $false
```

<!-- #TODO: Check, whether an array of IDs is actually supported -->

## Contributions

Feel free to send pull requests or fill out issues when you encounter them. I'm also completely open to adding direct maintainers/contributors and working together! :)

## Future plans

Version 1.0 contains all you'd need to be able to query all the endpoints, but there is still room for improvements. Some planned improvements for the project:

- [x] Allow child queries
- [x] Allow Simple Search strings instead of a JSON search filter
- [ ] Convert API time to current timezone of the executed script. The same for date/time based queries.
- [ ] Replace/improve new-autotask body with something more dynamic, allowing the use of the labels for picklists instead of having to enter data yourself.
- [ ] Add example filters for each resource
