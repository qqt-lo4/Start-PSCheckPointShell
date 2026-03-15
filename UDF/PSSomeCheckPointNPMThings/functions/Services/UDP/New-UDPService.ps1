function New-UDPService {
    <#
    .SYNOPSIS
        Creates a new UDP service in the Check Point management database.

    .DESCRIPTION
        Creates a UDP service with a name and port number.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new UDP service.

    .PARAMETER port
        UDP port number.

    .OUTPUTS
        [PSCustomObject] Created UDP service object.

    .EXAMPLE
        New-UDPService -name "MyUDP" -port 5000

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(Mandatory, Position = 1)]
        [ValidatePattern("^(([0-9]{1,5})|([0-9]{1,5}`-[0-9]{1,5}))$")]
        [string]$port,
        [switch]${set-if-exists},
        [switch]${match-for-any},
        [switch]${ignore-warnings},
        [Alias("description")]
        [string]$comments,
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $body = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("add-service-udp", $body)
    }
}