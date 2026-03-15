function Remove-ManagementAPI {
    <#
    .SYNOPSIS
        Removes a management connection from all global tracking variables.

    .DESCRIPTION
        Unregisters a management connection object (as returned by Connect-ManagementAPI)
        from all global tracking variables:
          - $Global:CPManagementHashtable  (all keys pointing to this management)
          - $Global:CPManagement           (array entry)
          - $Global:CPGateway              (all gateways whose .Management matches)
          - $Global:CPGatewayHashtable     (all keys whose value's .Management matches)
          - $Global:CPInteroperableDevices (all devices whose .Management matches)
          - $Global:MgmtAPI                (entry removed; set to $null if empty)

        Supports pipeline input to remove multiple connections at once.

    .PARAMETER ManagementInfo
        The management connection object to remove, as returned by Connect-ManagementAPI.

    .EXAMPLE
        Remove-ManagementAPI -ManagementInfo $mgmt

    .EXAMPLE
        $Global:CPManagement | Where-Object { $_.Address -eq "192.168.1.2" } | Remove-ManagementAPI

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [PSObject]$ManagementInfo
    )
    process {
        # Remove all hashtable keys pointing to this management
        if ($null -ne $Global:CPManagementHashtable) {
            $keysToRemove = @(
                $Global:CPManagementHashtable.Keys |
                    Where-Object { $Global:CPManagementHashtable[$_] -eq $ManagementInfo }
            )
            foreach ($key in $keysToRemove) {
                $Global:CPManagementHashtable.Remove($key)
            }
        }

        # Remove from global management list
        if ($null -ne $Global:CPManagement) {
            $Global:CPManagement = @($Global:CPManagement | Where-Object { $_ -ne $ManagementInfo })
        }

        # Remove gateways belonging to this management from global array
        if ($null -ne $Global:CPGateway) {
            $Global:CPGateway = @($Global:CPGateway | Where-Object { $_.Management -ne $ManagementInfo })
        }

        # Remove gateways belonging to this management from global hashtable
        if ($null -ne $Global:CPGatewayHashtable) {
            $keysToRemove = @(
                $Global:CPGatewayHashtable.Keys |
                    Where-Object { $Global:CPGatewayHashtable[$_].Management -eq $ManagementInfo }
            )
            foreach ($key in $keysToRemove) {
                $Global:CPGatewayHashtable.Remove($key)
            }
        }

        # Remove interoperable devices belonging to this management
        if ($null -ne $Global:CPInteroperableDevices) {
            $Global:CPInteroperableDevices = @(
                $Global:CPInteroperableDevices | Where-Object { $_.Management -ne $ManagementInfo }
            )
        }

        # Remove from MgmtAPI
        if ($null -ne $Global:MgmtAPI) {
            if ($Global:MgmtAPI -is [System.Array]) {
                $Global:MgmtAPI = @($Global:MgmtAPI | Where-Object { $_ -ne $ManagementInfo })
                if ($Global:MgmtAPI.Count -eq 0) { $Global:MgmtAPI = $null }
            } elseif ($Global:MgmtAPI -eq $ManagementInfo) {
                $Global:MgmtAPI = $null
            }
        }
    }
}
