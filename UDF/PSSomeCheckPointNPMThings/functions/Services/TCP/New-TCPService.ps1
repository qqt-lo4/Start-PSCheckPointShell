function New-TCPService {
    <#
    .SYNOPSIS
        Creates a new TCP service in the Check Point management database.

    .DESCRIPTION
        Creates a TCP service with a name and port number.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new TCP service.

    .PARAMETER port
        TCP port number.

    .OUTPUTS
        [PSCustomObject] Created TCP service object.

    .EXAMPLE
        New-TCPService -name "MyApp" -port 8080

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
        return $oMgmtInfo.CallAPI("add-service-tcp", $body)
    }
}