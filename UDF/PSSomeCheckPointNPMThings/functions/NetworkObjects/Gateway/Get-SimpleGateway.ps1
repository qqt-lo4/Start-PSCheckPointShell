function Get-SimpleGateway {
    <#
    .SYNOPSIS
        Retrieves a simple gateway object from the Check Point management database.

    .DESCRIPTION
        Returns one or all Check Point simple gateway objects by name, UID, or lists all.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] Gateway object(s).

    .EXAMPLE
        Get-SimpleGateway -name "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = "list")]
    Param(
        [object]$ManagementInfo,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name")]
        [Parameter(ParameterSetName = "uid")]
        [switch]${show-portals-certificate},
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [object]$order,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership},
        [Parameter(ParameterSetName = "list")]
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-simple-gateways", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-simple-gateways", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-simple-gateway", $hAPIParameters)
        }
    }
}