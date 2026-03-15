function Get-TCPService {
    <#
    .SYNOPSIS
        Retrieves a TCP service from the Check Point management database.

    .DESCRIPTION
        Returns a TCP service object by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] TCP service object.

    .EXAMPLE
        Get-TCPService -name "HTTP"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [object]$order,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership}
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-services-tcp", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-services-tcp", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-service-tcp", $hAPIParameters)
        }
    }
}
