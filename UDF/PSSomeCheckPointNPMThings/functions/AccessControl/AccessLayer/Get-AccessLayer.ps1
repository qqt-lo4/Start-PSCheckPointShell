function Get-AccessLayer {
    <#
    .SYNOPSIS
        Retrieves access layers from the Check Point management server.

    .DESCRIPTION
        Queries the Check Point Management API to retrieve access layers by UID, name,
        or as a paginated list. Supports filtering, ordering, and retrieving all pages.

    .PARAMETER ManagementInfo
        The management server connection object. If not specified, uses the cached connection.

    .PARAMETER uid
        The unique identifier of the access layer to retrieve.

    .PARAMETER name
        The name of the access layer to retrieve.

    .PARAMETER details-level
        The level of detail to return. Valid values: "uid", "standard", "full". Defaults to "standard".

    .PARAMETER limit
        Maximum number of results per page. Defaults to 50.

    .PARAMETER offset
        Number of results to skip. Defaults to 0.

    .PARAMETER filter
        A filter expression to narrow results.

    .PARAMETER order
        An ordering specification for the results.

    .PARAMETER All
        When specified, retrieves all pages of results automatically.

    .OUTPUTS
        PSObject. The access layer object(s) returned by the API.

    .EXAMPLE
        Get-AccessLayer -name "Network"

    .EXAMPLE
        Get-AccessLayer -All

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
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
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam "ManagementInfo"
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-access-layers", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-access-layers", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-access-layer", $hAPIParameters)
        }
    }
}
