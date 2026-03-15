function Get-CPGaiaConfiguration {
    <#
    .SYNOPSIS
        Retrieves the full Gaia configuration from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "show configuration" via clish on the gateway to retrieve the complete
        Gaia OS configuration (interfaces, routes, DNS, NTP, etc.).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] Full Gaia configuration output.

    .EXAMPLE
        Get-CPGaiaConfiguration -Firewall "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    $oFirewall, $oMgmtInfo = Get-GatwayAndManagementFromCache -ManagementInfo $ManagementInfo -Firewall $Firewall
    $oResult = Invoke-Cpridutil -ManagementInfo $oMgmtInfo -Firewall $oFirewall -Script "clish -c ""show configuration""" -LongOutput -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
    return $oResult."task-result"
}
