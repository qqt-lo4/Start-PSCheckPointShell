function Get-Objects {
    <#
    .SYNOPSIS
        Retrieves a collection of objects from the Check Point management database with optional filtering.

    .DESCRIPTION
        Searches for objects matching a filter expression, optionally restricted to IP-only objects.
        Supports pagination with limit and offset.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER filter
        Search filter expression.

    .PARAMETER ip-only
        Only return objects with IP addresses.

    .OUTPUTS
        [PSCustomObject] Collection of matching objects.

    .EXAMPLE
        Get-Objects -filter "10.0.0" -ip-only

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [string]$uids,
        [string]$filter,
        [object]$in,
        [object]$not,
        [switch]${ip-only},
        [ValidateRange(1, 500)]
        [int]$limit = 50,
        [int]$offset = 0,
        [object]$order,
        [string]${type},
        [switch]${show-membership},
        [switch]${dereference-group-members},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [switch]$All,
        [AllowEmptyString()]
        [string]$WriteProgressMessage = ""
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All", "WriteProgressMessage")
    }
    Process {
        if ($All) {
            return $oMgmtInfo.CallAllPagesAPI("show-objects", $hAPIParameters, @("objects"), $WriteProgressMessage)
        } else {
            return $oMgmtInfo.CallAPI("show-objects", $hAPIParameters)
        }        
    }
}