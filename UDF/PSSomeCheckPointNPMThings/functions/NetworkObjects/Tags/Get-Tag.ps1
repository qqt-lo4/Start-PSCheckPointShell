function Get-Tag {
    <#
    .SYNOPSIS
        Retrieves a tag object from the Check Point management database.

    .DESCRIPTION
        Returns one or more tag objects by name, UID, or lists all tags.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific tag to retrieve.

    .PARAMETER name
        Name of a specific tag to retrieve.

    .OUTPUTS
        [PSCustomObject] Tag object(s).

    .EXAMPLE
        Get-Tag -name "Environment:Production"

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
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "All")
        $oResult = $null
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                $oResult = $oMgmtInfo.CallAllPagesAPI("show-tags", $hAPIParameters)
            } else {
                $oResult = $oMgmtInfo.CallAPI("show-tags", $hAPIParameters)
            }
        } else {
            $oResult = $oMgmtInfo.CallAPI("show-tag", $hAPIParameters)
        }
        return $oResult
    }
}
