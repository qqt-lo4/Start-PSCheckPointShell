function Update-AddressRange {
    <#
    .SYNOPSIS
        Updates an address range object in the Check Point management database.

    .DESCRIPTION
        Modifies an existing address range's properties (IP addresses, name, comments).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the address range to update.

    .PARAMETER name
        Name of the address range to update.

    .PARAMETER ip-address-first
        New first IP address of the range.

    .PARAMETER ip-address-last
        New last IP address of the range.

    .PARAMETER new-name
        Rename the address range.

    .PARAMETER ignore-warnings
        Ignore warnings from the Management API.

    .PARAMETER comments
        New description/comments.

    .OUTPUTS
        [PSCustomObject] Updated address range object.

    .EXAMPLE
        Update-AddressRange -name "DMZ-Range" -ip-address-last "10.0.0.200"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, ParameterSetName = "name", Position = 0)]
        [string]$name,
        [string]${ip-address-first},
        [switch]${ipv4-address-first},
        [switch]${ipv6-address-first},
        [string]${ip-address-last},
        [switch]${ipv4-address-last},
        [switch]${ipv6-address-last},
        [string]${new-name},
        [switch]${ignore-warnings},
        [Alias("description")]
        [string]$comments,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("set-address-range", $hAPIParameters)
    }
}