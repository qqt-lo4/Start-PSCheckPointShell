function Update-HostObject {
    <#
    .SYNOPSIS
        Updates a host object in the Check Point management database.

    .DESCRIPTION
        Modifies an existing host object's properties (IP address, name, comments).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the host to update.

    .PARAMETER name
        Name of the host to update.

    .OUTPUTS
        [PSCustomObject] Updated host object.

    .EXAMPLE
        Update-HostObject -name "WebServer01" -ip-address "10.0.0.20"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, ParameterSetName = "name", Position = 0)]
        [string]$name,
        [string]${new-name},
        [string]${ip-address},
        [string]${ipv4-address},
        [string]${ipv6-address},
        [Alias("Description")]
        [string]$comments,
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
        return $oMgmtInfo.CallAPI("set-host", $hAPIParameters)
    }
}