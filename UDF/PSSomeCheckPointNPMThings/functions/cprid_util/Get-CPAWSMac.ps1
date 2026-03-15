function Get-CPAWSMac {
    <#
    .SYNOPSIS
        Retrieves the MAC address from AWS metadata on a Check Point gateway via cprid_util.

    .DESCRIPTION
        Queries the AWS instance metadata endpoint on the gateway to retrieve the MAC address
        of the primary network interface. Uses IMDSv2 token-based authentication.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] MAC address of the primary network interface.

    .EXAMPLE
        Get-CPAWSMac -Firewall "AWS-GW01"

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
        [string]$Token,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    return Get-CPAWSMetadata -ManagementInfo $ManagementInfo -Firewall $Firewall -Token $Token -MetadataURI "meta-data/mac" -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout -SingleLineResult
}