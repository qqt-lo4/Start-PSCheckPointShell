function Get-AddressRange {
    <#
    .SYNOPSIS
        Retrieves address range objects from the Check Point management database.

    .DESCRIPTION
        Returns one or more address range objects by name, UID, or lists all address ranges.
        Supports pagination and filtering when listing.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific address range to retrieve.

    .PARAMETER name
        Name of a specific address range to retrieve.

    .PARAMETER details-level
        Level of detail in the response: "uid", "standard", or "full". Default: "standard".

    .PARAMETER limit
        Maximum number of results per page. Default: 50.

    .PARAMETER offset
        Number of results to skip. Default: 0.

    .PARAMETER filter
        Search filter expression.

    .PARAMETER order
        Sort order for results.

    .PARAMETER show-membership
        Include group membership information.

    .PARAMETER All
        Retrieve all address ranges across all pages.

    .OUTPUTS
        [PSCustomObject] Address range object(s) from the Management API.

    .EXAMPLE
        Get-AddressRange -name "DMZ-Range"

    .EXAMPLE
        Get-AddressRange -All

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'list')]
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
                return $oMgmtInfo.CallAllPagesAPI("show-address-ranges", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-address-ranges", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-address-range", $hAPIParameters)
        }
    }
}
