function Create-ResourceDynamicParameter {
    $ParameterName = 'Resource'
    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $true
    $AttributeCollection.Add($ParameterAttribute)
    # Generate and set the ValidateSet. You definitely want to change this. This part populates your set. 
    $ResourceList = @( 
        "ActionTypes",
        "AdditionalInvoiceFieldValues",
        "Appointments",
        "AttachmentInfo",
        "BillingCodes",
        "BillingItemApprovalLevels",
        "BillingItems",
        "ChangeOrderCharges",
        "ChangeRequestLinks",
        "ChecklistLibraries",
        "ChecklistLibraryChecklistItems",
        "ChecklistLibraries",
        "ClassificationIcons",
        "ClientPortalUsers",
        "ComanagedAssociations",
        "Companies",
        "CompanyAlerts",
        "Companies",
        "CompanyAttachments",
        "Companies",
        "Companies",
        "CompanyLocations",
        "Companies",
        "CompanyNotes",
        "Companies",
        "CompanySiteConfigurations",
        "Companies",
        "CompanyTeams",
        "Companies",
        "CompanyToDos",
        "Companies",
        "CompanyWebhookExcludedResources",
        "CompanyWebhooks",
        "CompanyWebhookFields",
        "CompanyWebhooks",
        "CompanyWebhooks",
        "CompanyWebhookUdfFields",
        "CompanyWebhooks",
        "ConfigurationItemBillingProductAssociations",
        "ConfigurationItems",
        "ConfigurationItemCategories",
        "ConfigurationItemCategoryUdfAssociations",
        "ConfigurationItemCategories",
        "ConfigurationItemNotes",
        "ConfigurationItems",
        "ConfigurationItems",
        "ConfigurationItemTypes",
        "ContactBillingProductAssociations",
        "Contacts",
        "ContactGroupContacts",
        "ContactGroups",
        "ContactGroups",
        "Contacts",
        "ContactWebhookExcludedResources",
        "ContactWebhooks",
        "ContactWebhookFields",
        "ContactWebhooks",
        "ContactWebhooks",
        "ContactWebhookUdfFields",
        "ContactWebhooks",
        "ContractBillingRules",
        "Contracts",
        "ContractBlockHourFactors",
        "Contracts",
        "ContractBlocks",
        "Contracts",
        "ContractCharges",
        "Contracts",
        "ContractExclusionBillingCodes",
        "Contracts",
        "ContractExclusionRoles",
        "Contracts",
        "ContractExclusionSetExcludedRoles",
        "ContractExclusionSets",
        "ContractExclusionSetExcludedWorkTypes",
        "ContractExclusionSets",
        "ContractExclusionSets",
        "ContractMilestones",
        "Contracts",
        "ContractNotes",
        "Contracts",
        "ContractRates",
        "Contracts",
        "ContractRetainers",
        "Contracts",
        "ContractRoleCosts",
        "Contracts",
        "Contracts",
        "ContractServiceBundles",
        "Contracts",
        "ContractServiceBundleUnits",
        "Contracts",
        "ContractServices",
        "Contracts",
        "ContractServiceUnits",
        "Contracts",
        "ContractTicketPurchases",
        "Contracts",
        "Countries",
        "Currencies",
        "Departments",
        "ExpenseItems",
        "Expenses",
        "ExpenseReports",
        "Holidays",
        "HolidaySets",
        "HolidaySets",
        "InternalLocations",
        "InternalLocationWithBusinessHours",
        "InventoryItems",
        "InventoryItemSerialNumbers",
        "InventoryItems",
        "InventoryLocations",
        "InventoryTransfers",
        "Invoices",
        "InvoiceTemplates",
        "NotificationHistory",
        "Opportunities",
        "OpportunityAttachments",
        "Opportunities",
        "OrganizationalLevel1s",
        "OrganizationalLevel2s",
        "OrganizationalLevelAssociations",
        "OrganizationalResources",
        "OrganizationalLevelAssociations",
        "PaymentTerms",
        "Phases",
        "Projects",
        "PriceListMaterialCodes",
        "PriceListProducts",
        "PriceListProductTiers",
        "PriceListRoles",
        "PriceListServiceBundles",
        "PriceListServices",
        "PriceListWorkTypeModifiers",
        "ProductNotes",
        "Products",
        "Products",
        "ProductTiers",
        "Products",
        "ProductVendors",
        "Products",
        "ProjectAttachments",
        "Projects",
        "ProjectCharges",
        "Projects",
        "ProjectNotes",
        "Projects",
        "Projects",
        "PurchaseApprovals",
        "PurchaseOrderItemReceiving",
        "PurchaseOrderItems",
        "PurchaseOrderItems",
        "PurchaseOrders",
        "PurchaseOrders",
        "QuoteItems",
        "Quotes",
        "QuoteLocations",
        "Quotes",
        "QuoteTemplates",
        "ResourceRoleDepartments",
        "Resources",
        "ResourceRoleQueues",
        "Resources",
        "ResourceRoles",
        "Resources",
        "Resources",
        "ResourceServiceDeskRoles",
        "Resources",
        "ResourceSkills",
        "Resources",
        "Roles",
        "SalesOrders",
        "Opportunities",
        "ServiceBundles",
        "ServiceBundleServices",
        "ServiceBundles",
        "ServiceCalls",
        "ServiceCallTaskResources",
        "ServiceCallTasks",
        "ServiceCallTasks",
        "ServiceCalls",
        "ServiceCallTicketResources",
        "ServiceCallTickets",
        "ServiceCallTickets",
        "ServiceCalls",
        "ServiceLevelAgreementResults",
        "ServiceLevelAgreements",
        "Services",
        "ShippingTypes",
        "Skills",
        "SubscriptionPeriods",
        "Subscriptions",
        "Subscriptions",
        "SurveyResults",
        "Surveys",
        "TaskAttachments",
        "Tasks",
        "TaskNotes",
        "Tasks",
        "TaskPredecessors",
        "Tasks",
        "Tasks",
        "Projects",
        "TaskSecondaryResources",
        "Tasks",
        "TaxCategories",
        "Taxes",
        "TaxRegions",
        "TicketAdditionalConfigurationItems",
        "Tickets",
        "TicketAdditionalContacts",
        "Tickets",
        "TicketAttachments",
        "Tickets",
        "TicketCategories",
        "TicketCategoryFieldDefaults",
        "TicketCategories",
        "TicketChangeRequestApprovals",
        "Tickets",
        "TicketCharges",
        "Tickets",
        "TicketChecklistItems",
        "Tickets",
        "TicketHistory",
        "TicketNotes",
        "Tickets",
        "TicketRmaCredits",
        "Tickets",
        "Tickets",
        "TicketSecondaryResources",
        "Tickets",
        "TimeEntries",
        "UserDefinedFieldDefinitions",
        "UserDefinedFieldListItems",
        "UserDefinedFields",
        "WebhookEventErrorLogs",
        "WorkTypeModifiers")
    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute( $ResourceList )
    $AttributeCollection.Add($ValidateSetAttribute)
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
    $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
    return $RuntimeParameterDictionary
}

function Add-AutotaskBaseURI (
    [Parameter(Mandatory = $true)]$BaseURI
) {
    $Global:AutotaskBaseURI = $BaseURI
}

function Add-AutotaskAPIAuth (
    [Parameter(Mandatory = $true)]$ApiIntegrationcode,
    [Parameter(Mandatory = $true)]$username,
    [Parameter(Mandatory = $true)]$secret
) {
    $Global:AutotaskAuthHeader = @{
        ApiIntegrationcode = $ApiIntegrationcode
        Username           = $username
        Secret             = $secret
    }
    write-host "Enter your Autotask REST service URL." -ForegroundColor Yellow
    Add-AutotaskBaseURI

}

function Get-AutotaskAPIItem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][int]$ID
    )
    DynamicParam {
        Create-ResourceDynamicParameter
    }
    begin {
        if (!$Global:AutotaskAuthHeader -or !$Global:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $headers = $Global:AutotaskAuthHeader
        $headers.add('id',$ID)
        $SetURI = "$($BaseURI)/$($resource)/$ID" 
    }
    
    process {
        try {
            Invoke-RestMethod -Uri $SetURI -headers $Headers -Method Get
        }
        catch {
            write-error "Connecting to the Autotask API failed. Returned error: $($_.Exception.Message)"
        }

    }
}
function Search-AutotaskAPI {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]$SearchQuery
    )
    DynamicParam {
        Create-ResourceDynamicParameter
    }
    begin {
        if (!$Global:AutotaskAuthHeader -or !$Global:AutotaskBaseURI) {
            Write-Warning "You must first run Add-AutotaskAPIAuth before calling any other cmdlets" 
            break 
        }
        $headers = $Global:AutotaskAuthHeader
        $headers.add('search',$SearchQuery)
        $SetURI = "$($BaseURI)/$($resource)/query" 
    }
    process {
        try {
            Invoke-RestMethod -Uri $SetURI -headers $Headers -Method Get
        }
        catch {
            write-error "Connecting to the Autotask API failed. Returned error: $($_.Exception.Message)"
        }

    }
}
