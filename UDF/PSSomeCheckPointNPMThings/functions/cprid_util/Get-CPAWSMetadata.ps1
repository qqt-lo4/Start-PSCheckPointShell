function Get-CPAWSMetadata {
    <#
    .SYNOPSIS
        Retrieves AWS instance metadata from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Queries the AWS instance metadata service (IMDS) on the gateway using IMDSv2
        token-based authentication to retrieve instance information.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [PSCustomObject] AWS instance metadata.

    .EXAMPLE
        Get-CPAWSMetadata -Firewall "AWS-GW01"

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
        [string]$MetadataURI,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [switch]$SingleLineResult
    )
    $sToken = if ($Token) { $Token } else { Get-CPAWSMetadataToken -ManagementInfo $ManagementInfo -Firewall $Firewall -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout }
    $sScript = 'curl_cli -s -H \"X-aws-ec2-metadata-token: ' + $sToken + '\" --url http://169.254.169.254/latest/' + $MetadataURI
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}