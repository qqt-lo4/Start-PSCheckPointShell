function Expand-Group {
    <#
    .SYNOPSIS
        Recursively expands group members by resolving each member to its full object definition.

    .DESCRIPTION
        Takes a group object and resolves all its members (and nested group members)
        to their full object definitions from the management database.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject[]] Fully resolved member objects.

    .EXAMPLE
        Expand-Group -GroupName "DMZ_Servers"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [object]$ServiceGroup
    )

    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        $aNewMembers = @()
        foreach ($item in $ServiceGroup.members) {
            if ($item -is [string]) {
                $newItem = Get-Object -ManagementInfo $oMgmtInfo -uid $item -details-level full
            } else {
                $newItem = switch ($item.type) {
                    "service-group" {
                        Get-ServiceGroup -ManagementInfo $oMgmtInfo -Uid $item.uid -details-level ${details-level} -Recurse
                    }
                    "service-tcp" {
                        Get-TCPService -ManagementInfo $oMgmtInfo -Uid $item.uid -details-level ${details-level}
                    }
                    "service-udp" {
                        Get-UDPService -ManagementInfo $oMgmtInfo -Uid $item.uid -details-level ${details-level}
                    }
                    "group" {
                        Get-NetworkGroup -ManagementInfo $oMgmtInfo -Uid $item.uid -details-level ${details-level} -Recurse
                    }
                    "network" {
                        Get-NetworkObject -ManagementInfo $oMgmtInfo -Uid $item.uid -details-level ${details-level}
                    }
                    "host" {
                        Get-HostObject -ManagementInfo $oMgmtInfo -Uid $item.uid -details-level ${details-level}
                    }
                }
            }
            $aNewMembers += $newItem
        }
        $serviceGroup | Set-Property -Name "members" -Value $aNewMembers | Out-Null
    }
}