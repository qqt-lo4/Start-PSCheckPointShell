function Wait-Task {
    <#
    .SYNOPSIS
        Waits for a Check Point management task to complete with a configurable timeout.

    .DESCRIPTION
        Polls the task status until it completes (succeeded or failed) or the timeout
        is reached. Displays an optional progress message while waiting.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER task-id
        Task ID(s) to wait for.

    .PARAMETER Timeout
        Maximum wait time in seconds.

    .OUTPUTS
        [PSCustomObject] Final task result object.

    .EXAMPLE
        Wait-Task -task-id "abc123" -Timeout 120

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string[]]${task-id},
        [int]$Timeout = 20,
        [AllowNull()]
        [string]$WaitProgressMessage
    )
    $oMgmtAPI = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    $sTaskId = if (${task-id}) { ${task-id} } else { $oMgmtAPI.LatestTask }
    $iTimeout = $Timeout
    if ($WaitProgressMessage) {
        Write-Progress -Activity $WaitProgressMessage -Status "Waiting for task, timeout remaining" -PercentComplete 0
    }
    $oTask = Get-Task -task-id $sTaskId -ManagementInfo $oMgmtAPI
    while (($iTimeout -gt 0) -and ($oTask.tasks."progress-percentage" -lt 100)) {
        Start-Sleep -Seconds 1
        $oTask = Get-Task -task-id $sTaskId -ManagementInfo $oMgmtAPI
        $iTimeout -= 1
        if ($WaitProgressMessage) {
            Write-Progress -Activity $WaitProgressMessage -Status "Waiting for task, timeout remaining" -PercentComplete (((1 / $Timeout) * ($Timeout - $iTimeout)) * 100)
        }
    }
    if ($WaitProgressMessage) {
        if ($iTimeout -le 0) {
            Write-Progress -Activity $WaitProgressMessage -Status "Task failed because of timeout" -PercentComplete 100
        } else {
            Write-Progress -Activity $WaitProgressMessage -Status "Task finished before timeout" -PercentComplete 100
        }
    }
    return $oTask
}