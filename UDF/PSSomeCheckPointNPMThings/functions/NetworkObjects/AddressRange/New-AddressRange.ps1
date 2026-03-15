function New-AddressRange {
    <#
    .SYNOPSIS
        Creates a new address range object in the Check Point management database.

    .DESCRIPTION
        Creates an address range defined by a first and last IP address. Supports IPv4, IPv6,
        and generic IP address formats.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new address range.

    .PARAMETER ip-address-first
        First IP address of the range.

    .PARAMETER ip-address-last
        Last IP address of the range.

    .PARAMETER ignore-warnings
        Ignore warnings from the Management API.

    .PARAMETER comments
        Description/comments for the address range.

    .PARAMETER details-level
        Level of detail in the response. Default: "standard".

    .OUTPUTS
        [PSCustomObject] Created address range object.

    .EXAMPLE
        New-AddressRange -name "DMZ-Range" -ip-address-first "10.0.0.1" -ip-address-last "10.0.0.254"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'ip')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(Mandatory, ParameterSetName = "ip", Position = 1)]
        [string]${ip-address-first},
        [Parameter(Mandatory, ParameterSetName = "ipv4", Position = 1)]
        [string]${ipv4-address-first},
        [Parameter(Mandatory, ParameterSetName = "ipv6", Position = 1)]
        [string]${ipv6-address-first},
        [Parameter(Mandatory, ParameterSetName = "ip", Position = 2)]
        [string]${ip-address-last},
        [Parameter(Mandatory, ParameterSetName = "ipv4", Position = 2)]
        [string]${ipv4-address-last},
        [Parameter(Mandatory, ParameterSetName = "ipv6", Position = 2)]
        [string]${ipv6-address-last},
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
        return $oMgmtInfo.CallAPI("add-address-range", $hAPIParameters)
    }
}