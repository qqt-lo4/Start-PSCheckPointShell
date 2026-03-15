function Get-CPJumboHotfix {
    <#
    .SYNOPSIS
        Retrieves the installed Jumbo Hotfix Accumulator take number from a Check Point gateway.

    .DESCRIPTION
        Runs cpinfo -y fw1 on the gateway and parses the output to extract the Jumbo
        Hotfix take number.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] The Jumbo Hotfix take number (e.g., "77").

    .EXAMPLE
        Get-CPJumboHotfix -Firewall "GW01"

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
    $sCPInfoResult = Invoke-CPInfo -ManagementInfo $ManagementInfo -Firewall $Firewall -Arguments "-y fw1"
    return ($sCPInfoResult.Split("`r`n") | Where-Object { $_ -like "*Take*" }).Split(":")[1].Trim()
}