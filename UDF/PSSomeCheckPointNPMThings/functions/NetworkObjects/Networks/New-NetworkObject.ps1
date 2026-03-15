function New-NetworkObject {
    <#
    .SYNOPSIS
        Creates a new network object in the Check Point management database.

    .DESCRIPTION
        Creates a network (subnet) object with a name, subnet address, and mask.
        Supports subnet/mask-length and subnet4/subnet-mask formats.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER name
        Name for the new network object.

    .PARAMETER subnet
        Subnet address.

    .PARAMETER mask-length
        CIDR mask length.

    .OUTPUTS
        [PSCustomObject] Created network object.

    .EXAMPLE
        New-NetworkObject -name "DMZ_Network" -subnet "10.0.1.0" -mask-length 24

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding(DefaultParameterSetName = "Subnet")]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$name,
        [Parameter(ParameterSetName = "Subnet", Position = 1)]
        [string]$subnet,
        [Parameter(ParameterSetName = "Subnet4")]
        [string]$subnet4,
        [Parameter(ParameterSetName = "Subnet6")]
        [string]$subnet6,
        [Parameter(ParameterSetName = "Subnet", Position = 2)]
        [int]${mask-length},
        [Parameter(ParameterSetName = "Subnet4")]
        [int]${mask-length4},
        [Parameter(ParameterSetName = "Subnet6")]
        [int]${mask-length6},
        [Alias("description")]
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
        return $oMgmtInfo.CallAPI("add-network", $hAPIParameters)
    }
}
