function Get-Task {
    <#
    .SYNOPSIS
        Retrieves a task status from the Check Point management server.

    .DESCRIPTION
        Returns the current status of an asynchronous task by its task ID.
        If no task ID is provided, uses the latest task from the management session.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER task-id
        Task ID to query. If null, uses the latest task.

    .OUTPUTS
        [PSCustomObject] Task status object.

    .EXAMPLE
        Get-Task -task-id "abc123-def456"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string[]]${task-id},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard"
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $tID = if (${task-id}) {
            ${task-id}
        } else {
            $oMgmtInfo.LatestTask
        }
        $hAPIParameters = @{
            "task-id" = $tID
            "details-level" = ${details-level}
        }
    }
    Process {
        return $oMgmtInfo.CallAPI("show-task", $hAPIParameters)
    }
}