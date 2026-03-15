function Get-GatwayAndManagementFromCache {
    <#
    .SYNOPSIS
        Resolves a gateway and its associated management server from the local cache.

    .DESCRIPTION
        Looks up a gateway by name or object in the cached gateway list and returns
        both the gateway object and its associated management connection.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Gateway name or object to resolve.

    .OUTPUTS
        [Object[]] Two-element array: gateway object and management connection.

    .EXAMPLE
        $gw, $mgmt = Get-GatwayAndManagementFromCache -Firewall "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall
    )
    $oFirewall = if ($Firewall -is [string]) {
        $oFoundFW = $Global:CPGatewayHashtable[$Firewall]
        if ($null -eq $oFoundFW) {
            $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
            if ($oMgmtInfo) {
                Get-Gateway -ManagementInfo $oMgmtInfo -gateway $Firewall -details-level full
            } else {
                throw "No management found or provided"
            }
        } else {
            $oFoundFW
        }
    } else {
        $Firewall
    }
    $oMgmtInfo = if ($oFirewall) {
        $oFirewall.Management
    } else {
        $null
    }
    if (($null -ne $oFirewall) -and ($null -ne $oMgmtInfo)) {
        return $oFirewall, $oMgmtInfo
    } else {
        throw "gateway not found"
    }
}