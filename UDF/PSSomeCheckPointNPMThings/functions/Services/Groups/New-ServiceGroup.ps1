function New-ServiceGroup {
    <#
    .SYNOPSIS
        Creates a new service group in the Check Point management database.

    .DESCRIPTION
        Creates a service group with a name and optional initial members.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new service group.

    .PARAMETER members
        Initial service members to add.

    .OUTPUTS
        [PSCustomObject] Created service group object.

    .EXAMPLE
        New-ServiceGroup -name "Web_Services" -members "HTTP", "HTTPS"

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
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("ManagementInfo", "Remaining")
    }
    Process {
        $body = $hAPIParameters | ConvertTo-Json
        return $oMgmtInfo.CallAPI($oMgmtInfo.BaseURL + "add-service-group", $body)
    }
}
