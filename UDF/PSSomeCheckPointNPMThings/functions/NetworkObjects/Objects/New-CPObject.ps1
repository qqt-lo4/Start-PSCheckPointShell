function New-CPObject {
    <#
    .SYNOPSIS
        Creates a new Check Point object based on the provided value type.

    .DESCRIPTION
        Automatically determines the object type (host, network, range, or DNS domain)
        from the provided value and creates the appropriate object in the management database.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] Created object.

    .EXAMPLE
        New-CPObject -Value "10.0.0.1" -name "Host01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Position = 0)]
        [string]$Name,
        [Parameter(Mandatory, Position = 1)]
        [string]$Value,
        [switch]$IgnoreExisting,
        [AllowNull()]
        [string]$Comment
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    $oIP = Test-StringIsIP $Value -Mask32AsHost
    $oDNS = Test-StringIsDNSName $Value
    if ($oIP) {
        switch ($oIP.Type) {
            "Address" {
                $sName = if ($Name) { $Name } else { "IP_$($oIP.ipv4.ToString())"}
                $sValue = $oIP.ipv4.ToString()
                $hParam = @{
                    ManagementInfo = $oMgmtInfo 
                    name = $sName 
                    "ipv4-address" = $sValue
                }
                if ($Comment) {
                    $hParam.comments = $Comment   
                }
                New-HostObject @hParam -ignore-warnings
            }
            "Network" {
                $sNetworkValue = $oIP.ipv4.ToString() + "/" + $oIP.masklengthv4
                $sName = if ($Name) { $Name } else { "Network_$($sNetworkValue -replace "/", "_")"}
                $hParam = @{
                    ManagementInfo = $oMgmtInfo 
                    name = $sName 
                    subnet = $oIP.ipv4.ToString()
                    "mask-length" = $oIP.masklengthv4
                }
                if ($Comment) {
                    $hParam.comments = $Comment   
                }
                New-NetworkObject @hParam -ignore-warnings
            }
            "Range" {
                $sName = if ($Name) { $Name } else { "Range_" + $oIP.ipv4range }
                $hParam = @{
                    ManagementInfo = $oMgmtInfo 
                    name = $sName 
                    "ip-address-first" = $oIP.ipstart
                    "ip-address-last" = $oIP.ipend
                }
                if ($Comment) {
                    $hParam.comments = $Comment   
                }
                New-AddressRange @hParam -ignore-warnings
            }
        }
    } elseif ($oDNS) {
        $sName = if ($Name) { $Name } else { "DNS_" + $oIP.ipv4range }
        New-DNSDomain -ManagementInfo $oMgmtInfo -name $Value -comments $Comment
    } else {
        throw "Invalid value format"
    }
}