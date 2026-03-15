function Get-GatewayPublicInterface {
    <#
    .SYNOPSIS
        Retrieves the public-facing interface and NAT rules for a Check Point gateway.

    .DESCRIPTION
        Returns the public (non-RFC1918) interface of a gateway along with its
        NAT hide rules and external IP address.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the gateway.

    .PARAMETER name
        Name of the gateway.

    .OUTPUTS
        [PSCustomObject] Public interface details with NAT information.

    .EXAMPLE
        Get-GatewayPublicInterface -name "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
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
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $sGatewayId = $PSBoundParameters[$PSCmdlet.ParameterSetName]
        $oGateway = $oMgmtInfo.GatewaysHashtable[$sGatewayId]

        function Test-IsIncomingNatRule {
            Param(
                [Parameter(Mandatory)]
                [object]$NatRule
            )

        }
    }
    Process {
        $sMainIP = $oGateway."ipv4-address"
        $bMainIPIsPublic = if ((Test-IsRFC1918 -IPAddress $sMainIP) -eq "Yes") { $false } else { $true }
        $aInternetConnections = Get-CPInternetConnections -ManagementInfo $oMgmtInfo -Firewall $oGateway.name
        $bMainIsInInterfaces = $false
        if ($bMainIPIsPublic) {
            foreach ($oInterface in $aPublicInterfaces) {
                if (Test-IPInNetwork -IPAddress $sMainIP -Network $oInterface."ipv4-address" -SubnetMask $oInterface."ipv4-network-mask") {
                    $bMainIsInInterfaces = $true
                }
            }
        }
        $hResult = if ($aInternetConnections -and ($bMainIPIsPublic -and (-not $bMainIsInInterfaces))) {
            @{
                InternetConnections = $aInternetConnections
                Main = $sMainIP
            }
        } elseif ($aInternetConnections -and ($bMainIPIsPublic -and $bMainIsInInterfaces)) {
            @{
                InternetConnections = $aInternetConnections
            }
        } elseif (($aInternetConnections -eq $null) -and ($bMainIPIsPublic)) {
            @{
                Main = $sMainIP
            }
        } elseif ($aInternetConnections -and (-not $bMainIPIsPublic)) {
            @{
                InternetConnections = $aInternetConnections
            }
        } else {
            $null
        }
        if ($hResult -ne $null) {
            if ($oGateway.type -ne "cluster-member") {
                $oPolicyPackage = Get-PolicyPackage -ManagementInfo $oMgmtInfo -name $oGateway.policy."access-policy-name"
                $oNatRulebase = Get-NatRulebase -ManagementInfo $oMgmtInfo -package $oPolicyPackage.name -details-level full -All -Flatten -use-object-dictionary -UseCache:$UseCache -ExpandUID
                $hResult.Package = $oPolicyPackage
                $hResult.NatRulebase = $oNatRulebase
                $aApplicableNatRules = $oNatRulebase.rulebase | Where-Object { 
                    ($_.enabled -eq $true) `
                    -and (("Policy Targets" -in $_."install-on".name) -or ($oGateway.name -in $_."install-on".name)) `
                    -and (-not (Test-IsNoNatRule $_))
                } | Where-Object {
                    (-not (Test-IsInternalToInternalNatRule $_)) `
                } | Where-Object {
                    (-not (Test-IsPrivateToPublicInternalNATRule $_))
                }
                $hResult.ApplicableNatRules = $aApplicableNatRules
            }
        }
        return $hResult
    }
}
