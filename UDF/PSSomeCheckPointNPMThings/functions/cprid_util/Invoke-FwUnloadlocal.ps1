function Invoke-FwUnloadlocal {
    <#
    .SYNOPSIS
        Unloads the local firewall policy on a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "fw unloadlocal" on the gateway, which removes the currently loaded
        firewall policy. This is typically used for troubleshooting or maintenance.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] Command output.

    .EXAMPLE
        Invoke-FwUnloadlocal -Firewall "GW01"

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
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "fw unloadlocal" -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}
