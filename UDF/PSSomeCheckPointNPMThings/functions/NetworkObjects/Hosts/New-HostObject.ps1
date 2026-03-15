function New-HostObject {
    <#
    .SYNOPSIS
        Creates a new host object in the Check Point management database.

    .DESCRIPTION
        Creates a host object with a name and IP address. Supports IPv4, IPv6, and generic
        IP address formats. Can update an existing object if set-if-exists is specified.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new host object.

    .PARAMETER ip-address
        IP address of the host.

    .PARAMETER comments
        Description/comments for the host object.

    .OUTPUTS
        [PSCustomObject] Created host object.

    .EXAMPLE
        New-HostObject -name "WebServer01" -ip-address "10.0.0.10"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = "ip-address")]
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "ip-address", Position = 1)]
        [string]${ip-address},
        [Parameter(ParameterSetName = "ipv4-address")]
        [string]${ipv4-address},
        [Parameter(ParameterSetName = "ipv6-address")]
        [string]${ipv6-address},
        [Parameter(Position = 2)]
        [Alias("Description")]
        [AllowNull()]
        [string]$comments,
        [switch]${set-if-exists},
        [switch]${ignore-warnings},
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
        return $oMgmtInfo.CallAPI("add-host", $hAPIParameters)
    }
}