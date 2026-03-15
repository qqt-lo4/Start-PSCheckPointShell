function Get-ServiceGroup {
    <#
    .SYNOPSIS
        Retrieves a service group from the Check Point management database.

    .DESCRIPTION
        Returns a service group by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] Service group object.

    .EXAMPLE
        Get-ServiceGroup -name "Web_Services"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(ParameterSetName = "name", Position = 0)]
        [string]$name,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "full",
        [switch]${show-as-ranges},
        [switch]$Recurse,
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership},
        [Parameter(ParameterSetName = "list")]
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("Recurse", "ManagementInfo", "All")
        $oResult = $null
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "list") {
            if ($All) {
                $oResult = $oMgmtInfo.CallAllPagesAPI("show-service-groups", $hAPIParameters)
            } else {
                $oResult = $oMgmtInfo.CallAPI("show-service-groups", $hAPIParameters)
            }
        } else {
            $oResult = $oMgmtInfo.CallAPI("show-service-group", $hAPIParameters)
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
