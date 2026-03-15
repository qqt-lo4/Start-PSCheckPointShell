function Update-UDPService {
    <#
    .SYNOPSIS
        Updates an existing UDP service in the Check Point management database.

    .DESCRIPTION
        Modifies a UDP service's properties (port, name, comments).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name of the UDP service to update.

    .OUTPUTS
        [PSCustomObject] Updated UDP service object.

    .EXAMPLE
        Update-UDPService -name "MyUDP" -port 5001

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "name")]
        [string]$name,
        [Parameter(Mandatory, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 1)]
        [ValidatePattern("^(([0-9]{1,5})|([0-9]{1,5}`-[0-9]{1,5}))$")]
        [string]$port,
        [string]$comments,
        [string]${new-name},
        [switch]${match-for-any},
        [switch]${details-level},
        [switch]${ignore-warnings},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $body = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("set-service-udp", $body)
    }
}