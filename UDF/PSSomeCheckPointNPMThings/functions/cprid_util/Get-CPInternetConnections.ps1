function Get-CPInternetConnections {
    <#
    .SYNOPSIS
        Retrieves internet connection details from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Returns public-facing interface information including interface name, IP address,
        mask length and default gateway. Supports both Gaia Embedded (via clish) and
        standard Gaia (via dbedit and interface analysis).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [PSCustomObject[]] Objects with name, interface, ipv4-address, mask-length, and default-gw properties.

    .EXAMPLE
        Get-CPInternetConnections -Firewall "GW01"

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
    $oFirewall, $oMgmtInfo = Get-GatwayAndManagementFromCache -ManagementInfo $ManagementInfo -Firewall $Firewall
    if ($oFirewall."operating-system" -eq "Gaia Embedded") {
        $oCommandResult = Invoke-CpridutilClish -ManagementInfo $oMgmtInfo -Firewall $Firewall -Script "show internet-connections table" -WaitProgressMessage $WaitProgressMessage
        return $oCommandResult | ConvertFrom-AlignedText #-AsHashtable
    } else {
        $aPublicInterfaces = $oFirewall.interfaces | Where-Object { (Test-IsRFC1918 -IPAddress $_."ipv4-address") -eq "No" } 
        if (($aPublicInterfaces -is [array]) -and ($aPublicInterfaces.Count -ne 1)) {
            $oDBEditObject = Get-DBEditObject -ManagementInfo $oMgmtInfo -Table_name "network_objects" -Object_name $oFirewall.name
            return $oDBEditObject.network_objects_object.firewall_setting.misp_isps.unnamed_element | ForEach-Object { 
                $sInterfaceName = $_.misp_interface."#cdata-section"
                $oWanInterface = $oFirewall.interfaces | Where-Object { $_."interface-name" -eq $sInterfaceName } 
                [pscustomobject]@{
                    name = ($_."#text" | Remove-EmptyString -TrimOnly).Trim()
                    interface = $sInterfaceName
                    "ipv4-address" = $oWanInterface."ipv4-address"
                    "mask-length" = $oWanInterface."ipv4-mask-length"
                    "default-gw" = $_.misp_nexthop."#cdata-section"
                    #value = $_
                }
            }
        } else {
            return $aPublicInterfaces | Select-Object -Property @(
                @{l = "name" ; e = {"Internet $($_."interface-name")"}}
                @{l = "interface"; e = {$_."interface-name"}}
                @{l = "ipv4-address" ; e = {$_."ipv4-address"}}
                @{l = "mask-length" ; e = {$_."ipv4-mask-length"}}
                @{l = "default-gw" ; e = {
                    $routes = Invoke-CpridutilClish -ManagementInfo $oMgmtInfo -Firewall $oFirewall.name -Script 'show configuration static-route' -WaitProgressMessage "Get $($oFirewall.name) routes" -Regex "set static-route default nexthop gateway address (?<defgw>.+) on"
                    $routes.defgw
                }}
            )
        }
    }
}