function Invoke-CPInfo {
    <#
    .SYNOPSIS
        Runs cpinfo on a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes the cpinfo diagnostic command on a remote Check Point gateway.
        By default runs with "-y all" arguments to collect all information.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER Arguments
        Arguments to pass to cpinfo. Default: "-y all".

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] Raw cpinfo output.

    .EXAMPLE
        Invoke-CPInfo -Firewall "GW01"

    .EXAMPLE
        Invoke-CPInfo -Firewall "GW01" -Arguments "-y fw1"

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
        [string]$Arguments = "-y all",
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    $sScript = "cpinfo $Arguments"
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage
}