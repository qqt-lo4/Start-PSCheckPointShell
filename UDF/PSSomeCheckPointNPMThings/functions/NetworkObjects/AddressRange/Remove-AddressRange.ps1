function Remove-AddressRange {
    <#
    .SYNOPSIS
        Removes an address range object from the Check Point management database.

    .DESCRIPTION
        Deletes an address range identified by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the address range to delete.

    .PARAMETER name
        Name of the address range to delete.

    .PARAMETER ignore-warnings
        Ignore warnings from the Management API.

    .OUTPUTS
        [PSCustomObject] API response confirming deletion.

    .EXAMPLE
        Remove-AddressRange -name "DMZ-Range"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdLetBinding(DefaultParameterSetName = "name")]
    Param(
        [AllowNull()]
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
        $hAPIParameters = Get-FunctionParameters -RemoveParam "ManagementInfo"
    }
    Process {
        return $oMgmtInfo.CallAPI("delete-address-range", $hAPIParameters)
    }
}