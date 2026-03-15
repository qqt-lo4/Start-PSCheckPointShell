function Invoke-SessionDiscard {
    <#
    .SYNOPSIS
        Discards unpublished changes in the current Check Point management session.

    .DESCRIPTION
        Reverts all unpublished changes made during the current session.
        Optionally targets a specific session by UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific session to discard. If null, discards the current session.

    .OUTPUTS
        [PSCustomObject] API response.

    .EXAMPLE
        Invoke-SessionDiscard

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string]$uid
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        $hAPIParameters = if ($uid) {
            @{
                uid = $uid
            }
        } else {
            @{}
        } 
        return $oMgmtInfo.CallAPI("discard", $hAPIParameters)
    }
}
