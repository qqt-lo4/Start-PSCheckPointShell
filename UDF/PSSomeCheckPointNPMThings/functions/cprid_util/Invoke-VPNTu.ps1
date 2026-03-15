function Invoke-VpnTu {
    <#
    .SYNOPSIS
        Lists VPN tunnel information from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "vpn tu" commands on the gateway to list IKE SAs, IPSec SAs, or
        active tunnels. Optionally filters by peer IP address for IKE and IPSec modes.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .PARAMETER ListIKE
        List IKE Security Associations.

    .PARAMETER ListIPSec
        List IPSec Security Associations.

    .PARAMETER peer
        Optional peer IP address to filter IKE or IPSec results.

    .PARAMETER ListTunnels
        List active VPN tunnels.

    .OUTPUTS
        [String] VPN tunnel information output.

    .EXAMPLE
        Invoke-VpnTu -Firewall "GW01" -ListIKE

    .EXAMPLE
        Invoke-VpnTu -Firewall "GW01" -ListIPSec -peer "10.0.0.1"

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
        [int]$Timeout = 60,
        [Parameter(ParameterSetName = "list ike")]
        [switch]$ListIKE,
        [Parameter(ParameterSetName = "list ipsec")]
        [switch]$ListIPSec,
        [Parameter(ParameterSetName = "list ike")]
        [Parameter(ParameterSetName = "list ipsec")]
        [ipaddress]$peer,
        [Parameter(ParameterSetName = "list tunnels")]
        [switch]$ListTunnels
    )
    $sCommand = switch ($PSCmdlet.ParameterSetName) {
        "list ike" {
            if ($peer) {
                "vpn tu list peer_ike $($peer.ToString())"
            } else {
                "vpn tu list ike"
            }
        }
        "list ipsec" {
            if ($peer) {
                "vpn tu list peer_ipsec $($peer.ToString())"
            } else {
                "vpn tu list ike"
            }
        }
        "list tunnels" {
            "vpn tu list tunnels"
        }
    }
    return Invoke-CpridutilBash -ManagementInfo $ManagementInfo -Firewall $Firewall -Script $sCommand -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
}
