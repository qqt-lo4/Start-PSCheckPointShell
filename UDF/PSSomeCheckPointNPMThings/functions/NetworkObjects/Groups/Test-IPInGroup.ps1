function Test-IPInGroup {
    <#
    .SYNOPSIS
        Tests if an IP address is a member of a Check Point network group.

    .DESCRIPTION
        Checks whether a given IP address is contained in any of the group's members
        (hosts, networks, or address ranges), resolving nested groups recursively.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [Boolean] True if the IP is found in the group.

    .EXAMPLE
        Test-IPInGroup -IP "10.0.0.5" -GroupName "Blocked_IPs"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$IP,
        [Parameter(Mandatory, Position = 1)]
        [object]$Group
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    $aObjects = (Get-Objects -ManagementInfo $oMgmtInfo -filter $IP -ip-only).objects
    $oGroup = if ($Group -is [string]) { Get-NetworkGroup -group $Group } else { $Group }
    $sGroupInto = $oGroup.name
    $bResult = $false
    foreach ($o in $aObjects) {
        $oDetailedObject = Get-Object -uid $o.uid -ManagementInfo $oMgmtInfo -GetMemberOf
        if ($sGroupInto -in $oDetailedObject.groups.name) {
            $bResult = $true
        }
    }
    return $bResult
}