function Remove-ServiceGroup {
    <#
    .SYNOPSIS
        Deletes a service group from the Check Point management database.

    .DESCRIPTION
        Removes a service group identified by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] API response confirming deletion.

    .EXAMPLE
        Remove-ServiceGroup -name "Old_Services"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdLetBinding(DefaultParameterSetName = "name")]
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [switch]${ignore-warnings},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hAPIParameters = Get-FunctionParameters -RemoveParam "ManagementInfo"
    }
    Process {
        $body = $hAPIParameters | ConvertTo-Json
        return $oMgmtInfo.CallAPI($oMgmtInfo.BaseURL + "delete-host", $body)
    }
}