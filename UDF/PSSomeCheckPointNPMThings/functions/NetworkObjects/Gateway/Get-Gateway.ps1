function Get-Gateway {
    <#
    .SYNOPSIS
        Retrieves gateways and servers from the Check Point management database.

    .DESCRIPTION
        Returns Check Point gateways and servers. Can list all gateways or retrieve
        a specific one by name or UID. Combines simple gateways and clusters.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] Gateway object(s).

    .EXAMPLE
        Get-Gateway

    .EXAMPLE
        Get-Gateway -name "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = "all")]
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "all")]
        [ValidateRange(1, 500)]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "all")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "all")]
        [switch]${show-membership},
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name")]
        [string]$name,
        [Parameter(ParameterSetName = "ipv4-address")]
        [string]${ipv4-address},
        [Parameter(ParameterSetName = "ipv6-address")]
        [string]${ipv6-address},
        [Parameter(ParameterSetName = "gateway")]
        [string]$gateway,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [Parameter(ParameterSetName = "all")]
        [switch]$All
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hParam = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All", "uid", "name", "ipv4-address", "ipv6-address", "gateway")
        function Add-GatewayToGlobalArray {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$Gateway
            )
            if ($null -eq $Global:CPGateway) {
                $Global:CPGateway = @()
            }  
            $iExistingGatewayIndex = ($Global:CPGateway | Get-ItemIndex -Condition { $_.uid -eq $oGateway.uid })
            if ($iExistingGatewayIndex -eq -1) {
                $Global:CPGateway += $oGateway
            } else {
                $Global:CPGateway[$iExistingGatewayIndex] = $oGateway
            }
        }
        function Add-GatewayToGlobalHashtable {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$Gateway
            )
            if ($null -eq $Global:CPGatewayHashtable) {
                $Global:CPGatewayHashtable = @{}
            }
            $Global:CPGatewayHashtable[$Gateway.name] = $Gateway
            $Global:CPGatewayHashtable[$Gateway.uid] = $Gateway
            if ($Gateway."ipv4-address") { $Global:CPGatewayHashtable[$Gateway."ipv4-address"] = $Gateway }
            if ($Gateway."ipv6-address") { $Global:CPGatewayHashtable[$Gateway."ipv6-address"] = $Gateway }
        }
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "all") {
            $aResult = Get-GenericObjectCollection -Body $hParam -ManagementInfo $oMgmtInfo -APICommand "show-gateways-and-servers" -All:$All
            foreach ($oGateway in $aResult.objects) {
                if (-not $oGateway.Management) {
                    $oGateway | Add-Member -NotePropertyName "Management" -NotePropertyValue $oMgmtInfo
                }
                Add-GatewayToGlobalArray -Gateway $oGateway
                Add-GatewayToGlobalHashtable -Gateway $oGateway
            }
            return $aResult
        } else {
            $sParam = $($PSCmdlet.ParameterSetName)
            $sParamValue = $PSBoundParameters[$sParam]
            if ($sParam -eq "gateway") {
                $tIP = Test-StringIsIP $gateway -MaskForbidden -RangeForbidden
                $tGUID = Test-IsGuid $gateway
                $tName = $gateway -match "^[a-zA-Z][a-zA-Z0-9_-]{0,63}$"
                $sParam, $sParamValue = if ($tIP) {
                    if ($tIP.IPVersion -eq 4) {
                        "ipv4-address", $gateway
                    } elseif ($tIP.IPVersion -eq 6) {
                        "ipv6-address", $gateway
                    } else {
                        $null, $null
                    }
                } elseif ($tGUID) {
                    "uid", $gateway
                } elseif ($tName) {
                    "name", $gateway
                } else {
                    $null, $null
                }
            }
            if ($sParam -eq $null) {
                return $null
            } 
            $aGateways = Get-GenericObjectCollection  @hParam -ManagementInfo $oMgmtInfo -APICommand "show-gateways-and-servers" -All
            $aResult = $aGateways.objects | Where-Object { $_.$sParam -eq $sParamValue }
            foreach ($oGateway in $aResult) {
                $oGateway | Add-Member -NotePropertyName "Management" -NotePropertyValue $oMgmtInfo
                Add-GatewayToGlobalArray -Gateway $oGateway
                Add-GatewayToGlobalHashtable -Gateway $oGateway
            }
            return $aResult
        }
    }
}