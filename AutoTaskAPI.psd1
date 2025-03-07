#
# Module manifest for module 'AutoTaskAPI'
#
# Generated by: Kelvin Tegelaar - Kelvin@limenetworks.nl
#
# Generated on: 19/05/2020
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = '\AutotaskAPI.psm1'
    
    # Version number of this module.
    ModuleVersion     = '1.2.3'
    
    # Supported PSEditions
    # CompatiblePSEditions = @()
    
    # ID used to uniquely identify this module
    GUID              = '125f3875-e1de-48d1-afeb-17e91f36efe8'
    
    # Author of this module
    Author            = 'Kelvin Tegelaar - Kelvin@limenetworks.nl'
    
    # Company or vendor of this module
    CompanyName       = 'Lime Networks / CyberDrain.com'
    
    # Copyright statement for this module
    Copyright         = '(c) 2020 Kelvin Tegelaar - Kelvin@limenetworks.nl. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'This module allows you to connect to the Autotask REST API. The Autotask REST API was launched with version 2020.2'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Add-AutotaskBaseURI',
        'Add-AutotaskAPIAuth',
        'Get-AutotaskAPIResource',
        'New-AutotaskAPIResource',
        'Set-AutotaskAPIResource',
        'New-AutotaskBody',
        'Remove-AutotaskAPIResource'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
    
        PSData = @{
    
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Autotask', 'api', 'REST', 'AutotaskAPI', 'PSA', 'AutotaskPSA', 'Datto', 'CyberDrain')
    
            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/KelvinTegelaar/AutotaskAPI/blob/master/LICENSE'
    
            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/KelvinTegelaar/AutotaskAPI'
    
            # A URL to an icon representing this module.
            # IconUri = ''
    
            # ReleaseNotes of this module
            ReleaseNotes = 'Version 1.0 allows you to get, set, and create new items on the Autotask/Datto PSA API. For more information, check out the Autotask information page here https://www.datto.com/integrations?query=powershell&products=Autotask+PSA&categories=Middleware+%26+Developers or the Github project. Version 1.0.1 had minor fixes for error handling. Version 1.0.2 removed some repeatable code.'
    
        } # End of PSData hashtable
    
    } # End of PrivateData hashtable
    
    # HelpInfo URI of this module
    HelpInfoURI       = 'https://github.com/KelvinTegelaar/AutotaskAPI'
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
    
}
 