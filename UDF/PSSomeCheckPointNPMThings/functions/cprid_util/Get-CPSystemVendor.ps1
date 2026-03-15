function Get-CPSystemVendor {
    <#
    .SYNOPSIS
        Retrieves the system vendor string from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Reads /sys/class/dmi/id/sys_vendor on the gateway to determine the hardware vendor
        (e.g., "Check Point", "VMware, Inc.", "Amazon EC2").

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] The system vendor name.

    .EXAMPLE
        Get-CPSystemVendor -Firewall "GW01"

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
    $sScript = "cat /sys/class/dmi/id/sys_vendor"
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage
}