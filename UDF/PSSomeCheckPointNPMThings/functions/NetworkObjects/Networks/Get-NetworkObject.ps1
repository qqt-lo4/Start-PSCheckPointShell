function Get-NetworkObject {
    <#
    .SYNOPSIS
        Retrieves a network object from the Check Point management database.

    .DESCRIPTION
        Returns a network (subnet) object by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the network to retrieve.

    .PARAMETER name
        Name of the network to retrieve.

    .OUTPUTS
        [PSCustomObject] Network object.

    .EXAMPLE
        Get-NetworkObject -name "DMZ_Network"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdLetBinding(DefaultParameterSetName = "name")]
    Param(
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership},
        [Parameter(ParameterSetName = "list")]
        [switch]$All,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard"
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam "ManagementInfo"
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-networks", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-networks", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-network", $hAPIParameters)
        }
    }
}