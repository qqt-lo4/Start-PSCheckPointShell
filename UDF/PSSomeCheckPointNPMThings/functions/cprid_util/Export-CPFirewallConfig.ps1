function Export-CPFirewallConfig {
    <#
    .SYNOPSIS
        Exports the Gaia configuration from one or more Check Point gateways to files.

    .DESCRIPTION
        Retrieves the full Gaia configuration from each specified gateway using
        Get-CPGaiaConfiguration and saves it to a text file in the specified folder.
        File names follow the pattern: <gatewayName>_config.txt.

    .PARAMETER Firewall
        One or more gateway objects or names. If null, uses $Global:CPGateway.

    .PARAMETER FolderPath
        Destination folder for the exported configuration files. Must exist.

    .PARAMETER Timeout
        Maximum wait time in seconds per gateway. Default: 60.

    .OUTPUTS
        None. Creates text files in FolderPath.

    .EXAMPLE
        Export-CPFirewallConfig -FolderPath "C:\Configs"

    .EXAMPLE
        Export-CPFirewallConfig -Firewall "GW01", "GW02" -FolderPath "C:\Configs"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object[]]$Firewall,
        [Parameter(Mandatory)]
        [string]$FolderPath,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    $aFirewall = if ($Firewall) {
        $Firewall
    } else {
        $Global:CPGateway
    }
    if (-not (Test-Path $FolderPath -PathType Container)) {
        throw "Folder does not exists"
    }
    foreach ($oFirewall in $aFirewall) {
        $sFirewallName = if ($oFirewall -is [string]) { $oFirewall } else { $oFirewall.name }
        $sConfig = Get-CPGaiaConfiguration -Firewall $oFirewall -WaitProgressMessage "Export $sFirewallName config" -Timeout $Timeout
        $sConfig | Out-File -FilePath "$FolderPath\$sFirewallName`_config.txt"
    }
}