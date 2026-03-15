function Get-PolicyPackage {
    <#
    .SYNOPSIS
        Retrieves one or more policy packages from the Check Point management database.

    .DESCRIPTION
        Returns policy packages by name, UID, or lists all packages.
        Supports pagination and detail level control.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name of a specific policy package to retrieve.

    .PARAMETER uid
        UID of a specific policy package to retrieve.

    .OUTPUTS
        [PSCustomObject] Policy package object(s).

    .EXAMPLE
        Get-PolicyPackage -name "Standard"

    .EXAMPLE
        Get-PolicyPackage -All

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
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                return $oMgmtInfo.CallAllPagesAPI("show-packages", $hAPIParameters, "packages")
            } else {
                return $oMgmtInfo.CallAPI("show-packages", $hAPIParameters, "packages")
            }
        } else {
            return $oMgmtInfo.CallAPI("show-package", $hAPIParameters)
        }
    }
}
