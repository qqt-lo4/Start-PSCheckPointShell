function Get-GatewayPlatform {
    <#
    .SYNOPSIS
        Retrieves the platform information for a Check Point gateway.

    .DESCRIPTION
        Returns hardware and OS platform details (vendor, model, OS) for a gateway,
        combining data from show-asset-all, system vendor, and fw ver commands.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name of the gateway.

    .OUTPUTS
        [PSCustomObject] Platform information.

    .EXAMPLE
        Get-GatewayPlatform -name "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hParam = @{
            $($PSCmdlet.ParameterSetName) = $PSBoundParameters[$PSCmdlet.ParameterSetName]
        }
    }
    Process {
        return $oMgmtInfo.CallAPI("get-platform", $hParam)
    }
}