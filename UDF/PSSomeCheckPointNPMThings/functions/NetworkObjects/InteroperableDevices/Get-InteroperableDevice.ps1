function Get-InteroperableDevice {
    <#
    .SYNOPSIS
        Retrieves an interoperable device from the Check Point management database.

    .DESCRIPTION
        Returns an interoperable device (third-party VPN gateway) by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the interoperable device to retrieve.

    .PARAMETER name
        Name of the interoperable device to retrieve.

    .OUTPUTS
        [PSCustomObject] Interoperable device object.

    .EXAMPLE
        Get-InteroperableDevice -name "Partner-VPN-GW"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdLetBinding(DefaultParameterSetName = "name")]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [switch]$All,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard"
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-interoperable-devices", $hAPIParameters, "packages")
            } else {
                return $oMgmtInfo.CallAPI("show-interoperable-devices", $hAPIParameters, "packages")
            }
        } else {
            return $oMgmtInfo.CallAPI("show-interoperable-device", $hAPIParameters)
        }
    }
}