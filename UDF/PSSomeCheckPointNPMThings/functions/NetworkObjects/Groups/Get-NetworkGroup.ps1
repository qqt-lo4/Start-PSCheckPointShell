function Get-NetworkGroup {
    <#
    .SYNOPSIS
        Retrieves a network group from the Check Point management database.

    .DESCRIPTION
        Returns a network group by name, UID, or lists all groups.
        Supports recursive member expansion and pagination.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific group to retrieve.

    .PARAMETER name
        Name of a specific group to retrieve.

    .PARAMETER group
        Parent group name to filter by.

    .PARAMETER details-level
        Level of detail in the response: "uid", "standard", or "full". Default: "standard".

    .PARAMETER show-as-ranges
        When specified, displays group members as IP ranges instead of individual objects.

    .PARAMETER All
        When specified in list mode, retrieves all pages of results.

    .PARAMETER Recurse
        When specified, recursively expands nested group members.

    .OUTPUTS
        [PSCustomObject] Network group object(s) from the Management API.

    .EXAMPLE
        Get-NetworkGroup -name "Blocked_IPs"

    .EXAMPLE
        Get-NetworkGroup -All -Recurse

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
        [Parameter(ParameterSetName = "group")]
        [string]$group,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [Parameter(ParameterSetName = "uid")]
        [Parameter(ParameterSetName = "name")]
        [switch]${show-as-ranges},
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
        [switch]$Recurse
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All", "Recurse")
        $oResult = $null
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                $oResult = $oMgmtInfo.CallAllPagesAPI("show-groups", $hAPIParameters)
            } else {
                $oResult = $oMgmtInfo.CallAPI("show-groups", $hAPIParameters)
            }
        } else {
            $oResult = $oMgmtInfo.CallAPI("show-group", $hAPIParameters)
        }
        
        if ((-not ${show-as-ranges}.IsPresent) -and ($Recurse.IsPresent)) {
            if ($PSCmdlet.ParameterSetName -eq "list") {
                foreach ($oGroup in $oResult.objects) {
                    Expand-Group -ManagementInfo $oMgmtInfo -ServiceGroup $oGroup
                }
            } else {
                Expand-Group -ManagementInfo $oMgmtInfo -ServiceGroup $oResult
            }
        }
        return $oResult
    }
}
