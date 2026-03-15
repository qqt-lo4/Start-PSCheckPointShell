function Install-Policy {
    <#
    .SYNOPSIS
        Installs a policy package on Check Point gateways.

    .DESCRIPTION
        Pushes a policy package to one or more target gateways via the Management API.
        Supports access and threat prevention policy types.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER policy-package
        Name of the policy package to install.

    .PARAMETER targets
        Target gateway name(s) or UID(s) to install the policy on.

    .OUTPUTS
        [PSCustomObject] Policy installation task result.

    .EXAMPLE
        Install-Policy -policy-package "Standard" -targets "GW01", "GW02"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]${policy-package},
        [string[]]$targets,
        [bool]$access,
        [bool]${desktop-policy},
        [bool]$qos,
        [bool]${threat-prevention},
        [bool]${install-on-all-cluster-members-or-fail} = $true,
        [bool]${prepare-only} = $false,
        [string]$revision,
        [bool]${ignore-warnings},
        [switch]$EndTask
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "EndTask")
    }
    Process {
        $apiResult = $oMgmtInfo.CallAPI("install-policy", $hAPIParameters)
        $oMgmtInfo.LatestTask = $apiResult."task-id"
        $sTaskId = $apiResult."task-id"
        if ($WaitEnd) {
            return Wait-Task -ManagementInfo $oMgmtInfo -task-id $sTaskId
        } else {
            return $sTaskId
        }
    }
}