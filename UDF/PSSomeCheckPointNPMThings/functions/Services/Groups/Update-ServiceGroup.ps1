function Update-ServiceGroup {
    <#
    .SYNOPSIS
        Updates an existing service group in the Check Point management database.

    .DESCRIPTION
        Modifies a service group's members (add or remove) or properties.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name of the service group to update.

    .PARAMETER members
        Members to add or remove.

    .OUTPUTS
        [PSCustomObject] Updated service group object.

    .EXAMPLE
        Update-ServiceGroup -name "Web_Services" -members "HTTP_8080" -add

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
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
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining", "add", "remove")
        if ($members -and $add.IsPresent) {
            $hAPIParameters["members"] = @{
                "add" = $hAPIParameters["members"]
            }
        }
        if ($members -and $remove.IsPresent) {
            $hAPIParameters["members"] = @{
                "remove" = $hAPIParameters["members"]
            }
        }
    }
    Process {
        $body = $hAPIParameters | ConvertTo-Json
        return $oMgmtInfo.CallAPI($oMgmtInfo.BaseURL + "set-service-group", $body)
    }
}