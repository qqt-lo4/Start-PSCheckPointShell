function Invoke-SessionLogout {
    <#
    .SYNOPSIS
        Logs out from the Check Point Management API session.

    .DESCRIPTION
        Terminates the current API session. Any unpublished changes are discarded.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] API response confirming logout.

    .EXAMPLE
        Invoke-SessionLogout

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        return $oMgmtInfo.CallAPI("logout", @{})
    }
}
