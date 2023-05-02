# AutotaskAPI PowerShell Module

This is a PowerShell wrapper for the new Autotask REST API, released by Datto in version 2020.2. This API is a replacement of the SOAP API. The REST API is faster and easier to develop for, than the SOAP API. If you need to use the SOAP API for whatever reason, then check out the project [Autotask by ecitsolutions](https://github.com/ecitsolutions/Autotask). This is by far the best wrapper for the SOAP API.

For more information, check out the [Datto/Autotask](https://www.datto.com/integrations?query=powershell&products=Autotask+PSA&categories=Middleware+%26+Developers) page about this module too.

Some users wanted a benchmark of the new API. The following results have been performed on the sandbox of Autotask, to which I have a RTT of about 150-180MS.

Getting 721 tickets based on a title filter: "Title eq hello!"

REST: 9.23 seconds
SOAP: 134,14 seconds

Getting all active companies in sandbox (1000 companies)

REST: 9,5 seconds
SOAP: 86,6 seconds

## Installation instructions

This module has been published to the PowerShell Gallery. Use the following command to install:  

    install-module AutotaskAPI

## Usage

### Authentication

To get items using the Autotask API you'll first have to add the authentication headers using the `Add-AutotaskAPIAuth` function. Example:

    $Creds = get-credential
    
    Add-AutotaskAPIAuth -ApiIntegrationcode 'ABCDEFGH00100244MMEEE333' -credentials $Creds

When the command runs, You will be asked for credentials. Using these, we will try to decide the correct webservices URL for your zone based on the e-mail address. If this fails you must manually set the webservices URL.

    Add-AutotaskBaseURI -BaseURI https://webservices1.autotask.net/atservicesrest

The Base URI value has tab completion to help you find the correct one easily.

### Pagination

The API has automatic pagination, meaning if you are retrieving more than 500 records, the API will automatically fetch all items.

### Filters

To find resources using the API, execute the `Get-AutotaskAPIResource` function. For the `Get-AutotaskAPIResource` function, you will need either the ID of the resource you want to retrieve, or the JSON SearchQuery you want to execute.

**Examples:**

To find the company with ID 12345:

    Get-AutotaskAPIResource -Resource Companies -ID 12345

To get all companies that are Active:

    Get-AutotaskAPIResource -Resource Companies -SearchQuery '{"filter":[{"op":"eq","field":"isactive","value":"true"}]}
    
    or
    
    Get-AutotaskAPIResource -resource Companies -SimpleSearch "isactive eq $true"

For more filtering options, check out the [Autotask documentation](https://www.autotask.net/help/developerhelp/Content/APIs/REST/API_Calls/REST_Basic_Query_Calls.htm)

To get all companies that start with the letter A:

    Get-AutotaskAPIResource -resource Companies -SimpleSearch "companyname beginswith A"

To get all child alerts for company 1234

    Get-AutotaskAPIResource -Resource CompanyAlertsChild -ID 1234 -verbose

To get only child 7 in company id 1234

    Get-AutotaskAPIResource -Resource CompanyAlertsChild -ID 29683578 -childid 7

 It's also possible to use this module to combine stuff, for example to create a Microsoft Team for each open project:

    Import-Module MicrosoftTeams
    Connect-MicrosoftTeams
    Add-AutotaskAPIAuth
    $Projects = Get-AutotaskAPIResource -Resource Projects -SimpleSearch 'status ne completed'
    foreach ($Project in $Projects) {
        $NewTeam = New-Team -MailNickname "$($project.projectnumber)" -DisplayName "$($project.projectnumber) - $($project.name)" -Visibility "private"
        $TeamLeadEmail = (Get-AutotaskAPIResource -Resource resources -id $($project.projectLeadResourceID)).email
        Add-TeamUser -GroupId $NewTeam.GroupId -User $TeamLeadEmail
    }

To create a new company, we can either make the entire body ourselves, or use the `New-AutotaskBody` function.

    $Body = New-AutotaskBody -Resource Companies

This creates a body for the model Company. Definitions can be tab-completed. The body will contain all expected values. If you want an empty body instead, use:

    $Body = New-AutotaskBody -Resource Companies -NoContent

If you only want to know what picklist options are available, for a specific resource use the following:

(New-AutotaskBody -Resource Tickets -NoContent).status

This will print a list with all possible options.

After setting the values for the body you want, execute:

    New-AutotaskAPIResource -Resource Companies -Body $body

To set existing companies, use the `Set-AutotaskAPIResource` function. This uses the Patch method so remember to remove any properties you do not want updated.

    Set-AutotaskAPIResource -Body $body

Both `Set-AutotaskAPIResource` and `new-AutotaskAPIResource` accept pipeline input, for example, to change a title of a specific ticket:

    $Ticket = Get-AutotaskAPIResource -resource tickets -SimpleSearch "id eq 12345"

Or to close all tickets with the subject "Nope!"

    $TicketList = Get-AutotaskAPIResource -Resource Tickets -SimpleSearch "title eq Nope!"
    $TicketList | ForEach-Object { $_.status = "12" }
    $TicketList | Set-AutotaskAPIResource -Resource Tickets

Or a one-liner to change all companies webaddresses to "google.com"

    Get-AutotaskAPIResource -Resource Companies -SimpleSearch 'Isactive eq true' | ForEach-Object {$_.Webaddress = "www.google.com"; $_} | Set-AutotaskAPIResource -Resource companies

## Contributions

Feel free to send pull requests or fill out issues when you encounter them. I'm also completely open to adding direct maintainers/contributors and working together! :)

## Future plans

Version 1.0 contains all you'd need to be able to query all the endpoints, but there is still room for improvements. Some planned improvements for the project:

- [x] Allow child queries
- [x] Allow Simple Search strings instead of a JSON search filter
- [ ] Convert API time to current timezone of the executed script. The same for date/time based queries.
- [ ] Replace/improve new-autotask body with something more dynamic, allowing the use of the labels for picklists instead of having to enter data yourself.
- [ ] Add example filters for each resource
