function Invoke-FwVer {
    <#
    .SYNOPSIS
        Retrieves the firewall version and build number from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "fw ver" on the gateway and parses the output using regex to extract
        the model, version (e.g., R81.20) and build number.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [Hashtable] With keys: model, version, build.

    .EXAMPLE
        Invoke-FwVer -Firewall "GW01"

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
    $sRegexFwVer = "^This is Check Point's (?<model>.+)(?<version>R[0-9][0-9](\.[0-9][0-9])+).+Build (?<build>[0-9]+)$"
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "fw ver" -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout -Regex $sRegexFwVer
}
