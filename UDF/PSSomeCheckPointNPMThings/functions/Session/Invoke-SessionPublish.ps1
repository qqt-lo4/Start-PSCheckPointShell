function Invoke-SessionPublish {
    <#
    .SYNOPSIS
        Publishes the current session's changes in the Check Point management database.

    .DESCRIPTION
        Commits all changes made during the current session, making them visible to
        other administrators and available for policy installation. Optionally waits
        for the publish task to complete.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific session to publish. If null, publishes the current session.

    .PARAMETER WaitEnd
        Wait for the publish task to complete before returning.

    .PARAMETER WaitTimeout
        Maximum wait time in seconds when WaitEnd is specified. Default: 60.

    .OUTPUTS
        [String] Task ID, or [PSCustomObject] task result if WaitEnd is specified.

    .EXAMPLE
        Invoke-SessionPublish

    .EXAMPLE
        Invoke-SessionPublish -WaitEnd -WaitTimeout 120

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string]$uid,
        [switch]$WaitEnd,
        [int]$WaitTimeout = 60
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        $hParam = if ($uid) {
            @{
                uid = $uid
            }
        } else {
            @{}
        }
        $apiResult = $oMgmtInfo.CallAPI("publish", $hParam)
        $oMgmtInfo.LatestTask = $apiResult.json."task-id"
        $sTaskId = $apiResult."task-id"
        if ($WaitEnd) {
            return Wait-Task -ManagementInfo $oMgmtInfo -task-id $sTaskId -Timeout $WaitTimeout
        } else {
            return $sTaskId
        }
    }
}
