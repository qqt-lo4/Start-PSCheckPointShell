function Get-RecursiveGroupMembers {
    <#
    .SYNOPSIS
        Recursively retrieves all leaf members of a Check Point network group.

    .DESCRIPTION
        Resolves nested groups to return only the leaf objects (hosts, networks, ranges)
        that are ultimately contained in the group.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Uid
        UID of the group to expand.

    .OUTPUTS
        [PSCustomObject[]] Leaf member objects.

    .EXAMPLE
        Get-RecursiveGroupMembers -Uid "abc123-def456"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [string]$Uid
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    $oDictionnary = Get-ObjectsDictionnary -ManagementInfo $oMgmtInfo

    $oObject = $oDictionnary.Get($Uid)
    if ($oObject -eq $null) {
        throw "Can't get objet with uid $Uid"
    } else {
        if ($oObject.type -eq "group") {
            $aResult = @()
            foreach ($oMember in $oObject.members) {
                $sUID = if ($oMember -is [string]) {
                    $oMember
                } else {
                    $oMember.uid
                }
                $aResult += Get-RecursiveGroupMembers -ManagementInfo $oMgmtInfo -uid $sUID
            }
            return $aResult
        } else {
            return $oObject
        }
    }
}