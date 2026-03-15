function New-NetworkGroup {
    <#
    .SYNOPSIS
        Creates a new network group in the Check Point management database.

    .DESCRIPTION
        Creates a network group with a name and optional initial members.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new network group.

    .PARAMETER members
        Initial members to add to the group.

    .PARAMETER comments
        Description or comments for the group. Alias: "description".

    .PARAMETER ignore-warnings
        Ignore API warnings during creation.

    .OUTPUTS
        [PSCustomObject] Created network group object.

    .EXAMPLE
        New-NetworkGroup -name "Blocked_IPs" -members "IP_10.0.0.1", "Net_192.168.1.0_24"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(Position = 1)]
        [string[]]$members,
        [Alias("description")]
        [string]$comments,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [switch]${ignore-warnings},
        [Parameter(ValueFromRemainingArguments)]
        $Remaining
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        return $oMgmtInfo.CallAPI("add-group", $hAPIParameters)
    }
}
