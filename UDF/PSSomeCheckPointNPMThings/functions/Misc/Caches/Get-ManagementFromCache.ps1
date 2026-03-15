function Get-ManagementFromCache {
    <#
    .SYNOPSIS
        Resolves a management server connection object from the local cache or global variable.

    .DESCRIPTION
        Returns the management connection object, resolving it from the global $CPManagement
        variable if a name or index is provided, or using the global default if null.

    .PARAMETER Management
        Management server name, object, or index. If null, uses $Global:MgmtAPI.

    .OUTPUTS
        [Object] Management connection object.

    .EXAMPLE
        $mgmt = Get-ManagementFromCache -Management "MgmtServer01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [Parameter(Position = 0)]
        [object]$Management
    )
    if ($Management -is [string]) {
        $oManagement = $Global:CPManagementHashtable[$Management]
        if ($oManagement) {
            return $oManagement
        } else {
            throw "management not found"
        }
    } elseif ($null -eq $Management) {
        if ($Global:MgmtAPI) {
            return @($Global:MgmtAPI)
        } elseif ($Global:CPManagement) {
            return $Global:CPManagement
        } else {
            throw "management not found"
        }
    } else {
        return $Management
    }
}