function Get-CPAWSMetadataToken {
    <#
    .SYNOPSIS
        Retrieves an AWS IMDSv2 session token from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Requests a temporary session token from the AWS Instance Metadata Service v2 (IMDSv2)
        on the gateway. This token is required for subsequent metadata queries.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [String] IMDSv2 session token.

    .EXAMPLE
        $token = Get-CPAWSMetadataToken -Firewall "AWS-GW01"

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
    $sScript = 'curl_cli -s --request PUT -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\" --url http://169.254.169.254/latest/api/token'  
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sScript -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}