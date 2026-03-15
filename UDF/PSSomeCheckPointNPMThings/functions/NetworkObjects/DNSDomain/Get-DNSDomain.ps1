function Get-DNSDomain {
    <#
    .SYNOPSIS
        Retrieves a DNS domain object from the Check Point management database.

    .DESCRIPTION
        Returns a DNS domain object by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the DNS domain to retrieve.

    .PARAMETER name
        Name of the DNS domain to retrieve.

    .OUTPUTS
        [PSCustomObject] DNS domain object.

    .EXAMPLE
        Get-DNSDomain -name ".example.com"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
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
                return $oMgmtInfo.CallAllPagesAPI("show-dns-domains", $hAPIParameters)
            } else {
                return $oMgmtInfo.CallAPI("show-dns-domains", $hAPIParameters)
            }
        } else {
            return $oMgmtInfo.CallAPI("show-dns-domain", $hAPIParameters)
        }
    }
}
