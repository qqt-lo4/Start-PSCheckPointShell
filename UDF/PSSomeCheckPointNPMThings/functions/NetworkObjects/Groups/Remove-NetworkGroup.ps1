function Remove-NetworkGroup {
    <#
    .SYNOPSIS
        Removes a network group from the Check Point management database.

    .DESCRIPTION
        Deletes a network group identified by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the group to delete.

    .PARAMETER name
        Name of the group to delete.

    .PARAMETER ignore-warnings
        Ignore API warnings during deletion.

    .PARAMETER ignore-errors
        Ignore API errors during deletion.

    .OUTPUTS
        [PSCustomObject] API response confirming deletion.

    .EXAMPLE
        Remove-NetworkGroup -name "Old_Group"

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
        [switch]${ignore-errors},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam "ManagementInfo"
    }
    Process {
        return $oMgmtInfo.CallAPI("delete-group", $hAPIParameters)
    }
}