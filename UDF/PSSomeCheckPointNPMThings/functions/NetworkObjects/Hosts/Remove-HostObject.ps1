function Remove-HostObject {
    <#
    .SYNOPSIS
        Removes a host object from the Check Point management database.

    .DESCRIPTION
        Deletes a host object identified by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the host to delete.

    .PARAMETER name
        Name of the host to delete.

    .OUTPUTS
        [PSCustomObject] API response confirming deletion.

    .EXAMPLE
        Remove-HostObject -name "WebServer01"

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
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("delete-host", $hAPIParameters)
    }
}