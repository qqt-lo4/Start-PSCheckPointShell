@{
    # Module manifest for PSSomeCheckPointNPMThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeCheckPointNPMThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '4fdd31e4-e18a-4fe9-89ef-16bfaaf66aff'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Check Point Management (On-Premise) functions'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('Check Point', 'CheckPoint', 'Management', 'Firewall', 'Gateway')
            ProjectUri = ''
        }
    }
}
