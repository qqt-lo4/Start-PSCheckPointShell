function Get-HostObject {
    <#
    .SYNOPSIS
        Retrieves host objects from the Check Point management database.

    .DESCRIPTION
        Returns one or more host objects by name, UID, or lists all hosts.
        Supports pagination and filtering when listing.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of a specific host to retrieve.

    .PARAMETER name
        Name of a specific host to retrieve.

    .OUTPUTS
        [PSCustomObject] Host object(s) from the Management API.

    .EXAMPLE
        Get-HostObject -name "WebServer01"

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
                return $oMgmtInfo.CallAllPagesAPI("show-hosts", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-hosts", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-host", $hAPIParameters)
        }
    }
}
