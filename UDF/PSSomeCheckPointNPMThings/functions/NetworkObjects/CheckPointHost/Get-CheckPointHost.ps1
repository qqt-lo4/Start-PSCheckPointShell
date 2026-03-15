function Get-CheckPointHost {
    <#
    .SYNOPSIS
        Retrieves a Check Point host object from the management database.

    .DESCRIPTION
        Returns a Check Point host (management server or log server) by name or UID.
        Uses auto-detection to determine the correct API call based on object type.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the Check Point host to retrieve.

    .PARAMETER name
        Name of the Check Point host to retrieve.

    .OUTPUTS
        [PSCustomObject] Check Point host object.

    .EXAMPLE
        Get-CheckPointHost -name "MgmtServer"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'detect')]
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, ParameterSetName = "name", Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [ValidateRange(1, 500)]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [object[]]$order,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
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
                $oMgmtInfo.CallAllPagesAPI("show-checkpoint-hosts", $hAPIParameters)
            } else {
                $oMgmtInfo.CallAPI("show-checkpoint-hosts", $hAPIParameters)
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "detect") {
            foreach ($oMgmt in $oMgmtInfo) {
                $aManagementObjects = (Get-CheckPointHost -ManagementInfo $oMgmt -details-level full -All).objects
                $sAddress = if (Test-StringIsIP $oMgmt.Address) {
                    $oMgmt.Address
                } else {
                    $oMgmt.Address.Split(".")[0]
                }
                $aManagementObjects | Where-Object { ($_.name -eq $sAddress) -or ($_."ipv4-address" -eq $sAddress ) }
            }
        } else {
            $oMgmtInfo.CallAPI("show-checkpoint-hosts", $hAPIParameters)
        }
    }
}
