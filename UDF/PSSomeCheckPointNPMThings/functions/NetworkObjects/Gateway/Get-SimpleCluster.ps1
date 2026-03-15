function Get-SimpleCluster {
    <#
    .SYNOPSIS
        Retrieves a simple cluster object from the Check Point management database.

    .DESCRIPTION
        Returns one or all Check Point cluster objects by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] Cluster object(s).

    .EXAMPLE
        Get-SimpleCluster -name "Cluster01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "uid")]
        [Parameter(ParameterSetName = "name")]
        [int]${limit-interfaces} = 50,
        [Parameter(ParameterSetName = "uid")]
        [Parameter(ParameterSetName = "name")]
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
                return $oMgmtInfo.CallAllPagesAPI("show-simple-clusters", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-simple-clusters", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-simple-cluster", $hAPIParameters)
        }
    }
}