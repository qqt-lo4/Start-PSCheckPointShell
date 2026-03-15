function New-DNSDomain {
    <#
    .SYNOPSIS
        Creates a new DNS domain object in the Check Point management database.

    .DESCRIPTION
        Creates a DNS domain object with a name and optional comments.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        DNS domain name (e.g., ".example.com").

    .PARAMETER comments
        Description/comments for the DNS domain.

    .OUTPUTS
        [PSCustomObject] Created DNS domain object.

    .EXAMPLE
        New-DNSDomain -name ".example.com" -comments "External domain"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [switch]${is-sub-domain} = $false,
        [Alias("Description")]
        [AllowNull()]
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
        return $oMgmtInfo.CallAPI("add-dns-domain", $hAPIParameters)
    }
}