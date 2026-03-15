function Update-NetworkGroup {
    <#
    .SYNOPSIS
        Updates a network group's members in the Check Point management database.

    .DESCRIPTION
        Adds or removes members from a network group. Cannot add and remove in the same call.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name of the group to update.

    .PARAMETER uid
        UID of the group to update.

    .PARAMETER members
        Members to add or remove.

    .PARAMETER add
        Add the specified members to the group.

    .PARAMETER remove
        Remove the specified members from the group.

    .OUTPUTS
        [PSCustomObject] Updated group object.

    .EXAMPLE
        Update-NetworkGroup -name "DMZ_Servers" -members "Web03" -add

    .EXAMPLE
        Update-NetworkGroup -name "DMZ_Servers" -members "Web01" -remove

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "name")]
        [string]$name,
        [Parameter(Mandatory, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 1)]
        [string[]]$members,
        [switch]$add,
        [switch]$remove,
        [string]$comments,
        [string]${new-name},
        [switch]${details-level},
        [switch]${ignore-warnings},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        if ($remove.IsPresent -and $add.IsPresent) {
            throw [System.ArgumentException] "Can't remove and add members at the same time"
        }
        if ((-not $members) -and (($remove.IsPresent) -or ($add.IsPresent))) {
            throw [System.ArgumentException] "Can't add or remove 0 elements"
        }
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining", "add", "remove")
        if ($members -and $add) {
            # $aAdd = if (($hAPIParameters["members"] -is [array]) -and ($hAPIParameters["members"].Count -eq 1)) {
            #     ($hAPIParameters["members"])[0]
            # } else {
            #     $hAPIParameters["members"]
            # }
            $aAdd = $hAPIParameters["members"]
            $hAPIParameters["members"] = @{
                "add" = $aAdd
            }
        }
        if ($members -and $remove) {
            $hAPIParameters["members"] = @{
                "remove" = $hAPIParameters["members"]
            }
        }
    }
    Process {
        return $oMgmtInfo.CallAPI("set-group", $hAPIParameters)
    }
}