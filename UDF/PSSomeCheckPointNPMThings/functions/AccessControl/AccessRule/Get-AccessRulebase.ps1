function Get-AccessRulebase {
    <#
    .SYNOPSIS
        Retrieves the access rulebase from the Check Point management server.

    .DESCRIPTION
        Queries the Check Point Management API to retrieve the access rulebase for a given
        policy package. Supports filtering, ordering, pagination, and retrieving all pages.

    .PARAMETER ManagementInfo
        The management server connection object. If not specified, uses the cached connection.

    .PARAMETER uid
        The unique identifier of a specific rulebase to retrieve.

    .PARAMETER name
        The name of the rulebase to retrieve.

    .PARAMETER limit
        Maximum number of results per page. Defaults to 50.

    .PARAMETER offset
        Number of results to skip. Defaults to 0.

    .PARAMETER filter
        A filter expression to narrow results.

    .PARAMETER order
        An ordering specification for the results.

    .PARAMETER package
        The policy package name.

    .PARAMETER show-membership
        When specified, includes group membership information.

    .PARAMETER show-hits
        When specified, includes hit count information.

    .PARAMETER show-as-ranges
        When specified, displays address ranges instead of subnets.

    .PARAMETER details-level
        The level of detail to return. Valid values: "uid", "standard", "full". Defaults to "standard".

    .PARAMETER All
        When specified, retrieves all pages of results automatically.

    .OUTPUTS
        PSObject. The access rulebase object(s) returned by the API.

    .EXAMPLE
        Get-AccessRulebase -package "Standard" -All

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding(DefaultParameterSetName = 'list')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [int]$limit = 50,
        [int]$offset = 0,
        [string]$filter,
        [object]$order,
        [string]$package,
        [switch]${show-membership},
        [switch]${show-hits},
        [switch]${show-as-ranges},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
    }
    Process {
        if ($All) {
            return $oMgmtInfo.CallAllPagesAPI("show-access-rulebase", $hAPIParameters, "rulebase")
        } else {
            return $oMgmtInfo.CallAPI("show-access-rulebase", $hAPIParameters, "rulebase")
        }
    }
}