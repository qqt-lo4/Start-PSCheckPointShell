function Get-ObjectTagValue {
    <#
    .SYNOPSIS
        Retrieves the value portion of a named tag assigned to a Check Point object.

    .DESCRIPTION
        Parses the tags of a Check Point object to find a tag matching the specified name
        pattern and returns its value portion (after the separator).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [String] Tag value, or $null if not found.

    .EXAMPLE
        Get-ObjectTagValue -Object $gwObject -TagName "Environment"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [object]$Object,
        [string]$TagName
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $oObject = if ($Object -is [string]) {
            $hObjectID = (Resolve-CPObjectIdentifier -Identifier $Object)
            Get-Object @hObjectID -ManagementInfo $oMgmtInfo
        } else {
            $Object
        }
    }
    Process {
        $oTag = $oObject.tags | Where-Object { $_.name -like "$TagName`:*" }
        if ($oTag) {
            return $oTag.name.SubString($TagName.Length + 1)
        } else {
            return $null
        }
    }
}