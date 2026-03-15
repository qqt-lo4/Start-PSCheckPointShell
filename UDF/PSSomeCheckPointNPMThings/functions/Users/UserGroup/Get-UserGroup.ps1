function Get-UserGroup {
    <#
    .SYNOPSIS
        Retrieves a user group from the Check Point management database.

    .DESCRIPTION
        Returns one or more user groups by name, UID, or lists all user groups.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific user group to retrieve.

    .PARAMETER name
        Name of a specific user group to retrieve.

    .OUTPUTS
        [PSCustomObject] User group object(s).

    .EXAMPLE
        Get-UserGroup -name "VPN_Users"

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
        $hAPIParameters = Get-FunctionParameters -RemoveParam "ManagementInfo"
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-user-groups", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-user-groups", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-user-group", $hAPIParameters)
        }
    }
}