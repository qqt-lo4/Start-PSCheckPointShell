function Test-GatewayHasPublicInterface {
    <#
    .SYNOPSIS
        Tests if a Check Point gateway has a public-facing interface.

    .DESCRIPTION
        Checks whether a gateway has at least one interface with a non-RFC1918 IP address.
        Supports caching to avoid repeated API calls.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the gateway.

    .PARAMETER name
        Name of the gateway.

    .PARAMETER UseCache
        Use cached gateway details instead of querying the API.

    .OUTPUTS
        [Boolean] True if the gateway has a public interface.

    .EXAMPLE
        Test-GatewayHasPublicInterface -name "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name")]
        [string]$name,
        [Parameter(ParameterSetName = "gateway")]
        [object]$gateway,
        [switch]$UseCache
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $sParam = $($PSCmdlet.ParameterSetName)
        $sParamValue = $PSBoundParameters[$PSCmdlet.ParameterSetName]
        $hParam = @{
            $sParam = $sParamValue
        }
        if ($UseCache -and ($Global:GatewayCache -eq $null)) {
            $Global:GatewayCache = Get-Gateway -ManagementInfo $oMgmtInfo -details-level full -All
        }
    }
    Process {
        $oGateway = if($gateway) {
            $gateway
        } else {
            if ($UseCache) {
                $Global:GatewayCache.objects | Where-Object { $_.$sParam -eq $sParamValue }
            } else {
                Get-Gateway @hParam -ManagementInfo $oMgmtInfo -details-level full
            }
        }
        if ((Test-IsRFC1918 -IPAddress $oGateway."ipv4-address") -eq "Yes") {
            foreach ($ip in $oGateway.interfaces."ipv4-address") {
                if ((Test-IsRFC1918 $ip) -eq "No") {
                    return $true
                }
            }
            return $false
        } else {
            return $true
        }
    }
}