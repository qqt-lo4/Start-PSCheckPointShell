function Get-UDPService {
    <#
    .SYNOPSIS
        Retrieves a UDP service from the Check Point management database.

    .DESCRIPTION
        Returns a UDP service object by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] UDP service object.

    .EXAMPLE
        Get-UDPService -name "DNS_UDP"

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
                return $oMgmtInfo.CallAllPagesAPI("show-services-udp", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-services-udp", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-service-udp", $hAPIParameters)
        }
    }
}
