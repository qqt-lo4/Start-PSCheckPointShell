function Invoke-RunScript {
    <#
    .SYNOPSIS
        Executes a script on a Check Point target via the Management API run-script command.

    .DESCRIPTION
        Runs a script on a management server or gateway target using the Management API.
        Supports waiting for task completion with a progress message and configurable timeout.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER script-name
        Name for the script task.

    .PARAMETER script
        The script content to execute.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting for completion.

    .PARAMETER timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [PSCustomObject] Task result object.

    .EXAMPLE
        Invoke-RunScript -script-name "Check version" -script "fw ver" -targets "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "script-name")]
        [string]${script-name},
        [string[]]$targets,
        [ValidateSet("repository", "one time")]
        [string]${script-type} = "one time",
        [string]$script,
        [string]${script-base64},
        [string]${arguments},
        [string]$comments,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$timeout = 60,
        [AllowNull()]
        [string]$WaitProgressMessage
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hParam = Get-FunctionParameters -RemoveParam @("ManagementInfo", "WaitProgressMessage") -RenameParam @{"arguments" = "args"}
    }
    Process {
        if ($null -eq $hParam.targets) {
            $hParam.targets = $oMgmtInfo.Object.name
        }
        $oTask = $oMgmtInfo.CallAPI($oMgmtInfo.BaseURL + "run-script", $hParam)
        $sTaskId = $oTask.tasks."task-id"
        Wait-Task -task-id $sTaskId -Timeout $timeout -ManagementInfo $oMgmtInfo -WaitProgressMessage $WaitProgressMessage | Out-Null
        $oTaskResult = Get-Task -ManagementInfo $oMgmtInfo -task-id $sTaskId -details-level full
        $oResult = $oTaskResult.tasks
        $sTaskResponse = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($oResult.'task-details'.responseMessage))
        $oResult | Add-Member -NotePropertyName "task-result" -NotePropertyValue $sTaskResponse
    }
    End {
        return $oResult
    }
}