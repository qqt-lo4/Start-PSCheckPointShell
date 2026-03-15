function Get-CPAzureMetadata {
    <#
    .SYNOPSIS
        Retrieves Azure instance metadata from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Queries the Azure Instance Metadata Service (IMDS) on the gateway to retrieve
        VM information such as instance type, location, and network configuration.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [PSCustomObject] Azure instance metadata.

    .EXAMPLE
        Get-CPAzureMetadata -Firewall "Azure-GW01"

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
    $sScript = 'curl_cli -s -H Metadata:true --max-time 2 ""http://169.254.169.254/metadata/instance?api-version=2025-04-07""'
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}