function Get-NatRulebase {
    <#
    .SYNOPSIS
        Retrieves the NAT rulebase from the Check Point management server.

    .DESCRIPTION
        Queries the Check Point Management API to retrieve the NAT rulebase for a given
        policy package. Supports pagination, caching, flattening nested sections, and
        expanding UIDs to full object representations using the objects dictionary.

    .PARAMETER ManagementInfo
        The management server connection object. If not specified, uses the cached connection.

    .PARAMETER package
        The policy package name to retrieve NAT rules from.

    .PARAMETER limit
        Maximum number of results per page. Defaults to 50.

    .PARAMETER offset
        Number of results to skip. Defaults to 0.

    .PARAMETER filter
        A filter expression to narrow results.

    .PARAMETER filter-settings
        A hashtable of filter settings.

    .PARAMETER order
        An array of ordering specifications.

    .PARAMETER use-object-dictionary
        When specified, uses the object dictionary for UID resolution.

    .PARAMETER dereference-group-members
        When specified, expands group members inline.

    .PARAMETER show-membership
        When specified, includes group membership information.

    .PARAMETER details-level
        The level of detail to return. Valid values: "uid", "standard", "full". Defaults to "standard".

    .PARAMETER ExpandUID
        When specified, resolves all UIDs in the rulebase to their full object representations.

    .PARAMETER Flatten
        When specified, flattens nested rulebase sections into a single list.

    .PARAMETER UseCache
        When specified, caches results in a global variable to avoid redundant API calls.

    .PARAMETER All
        When specified, retrieves all pages of results automatically.

    .OUTPUTS
        PSObject. The NAT rulebase with optional flattening and UID expansion.

    .EXAMPLE
        Get-NatRulebase -package "Standard" -All -Flatten

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding(DefaultParameterSetName = 'name')]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$package,
        [int]$limit = 50,
        [int]$offset = 0,
        [string]$filter,
        [hashtable]${filter-settings},
        [hashtable[]]$order,
        [switch]${use-object-dictionary},
        [switch]${dereference-group-members},
        [switch]${show-membership},
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [switch]$ExpandUID,
        [switch]$Flatten,
        [switch]$UseCache,
        [switch]$All
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hAPIParameters = Get-FunctionParameters -RemoveParam @("All", "ManagementInfo", "Flatten", "ExpandUID", "UseCache")
    }
    Process {
        #Write-Progress "Getting $package NAT rules"
        $hGetObjectCollArgs = @{
            Body = $hAPIParameters 
            APICommand = "show-nat-rulebase" 
            All = $All 
            ManagementInfo = $oMgmtInfo 
            AllObjectsProperty = "rulebase", "objects-dictionary"
            WriteProgressMessage = "Getting $package NAT rules"
        }
        if ($UseCache) {
            if ($null -eq $Global:CPNatRules) {
                $Global:CPNatRules = @{}
            }
            if ($Global:CPNatRules[$package]) {
                return $Global:CPNatRules[$package]
            } else {
                $oResult = $oMgmtInfo.CallAllPagesAPI("show-nat-rulebase", $hAPIParameters, @("rulebase", "objects-dictionary"), "Getting $package NAT rules")  #Get-GenericObjectCollection @hGetObjectCollArgs
                $Global:CPNatRules[$package] = $oResult
            }
        } else {
            $oResult = $oMgmtInfo.CallAllPagesAPI("show-nat-rulebase", $hAPIParameters, @("rulebase", "objects-dictionary"), "Getting $package NAT rules") #Get-GenericObjectCollection @hGetObjectCollArgs
        }
        if ($Flatten) {
            $oResult.rulebase = Get-FlattenedRulebase $oResult.rulebase
        }
        if ($ExpandUID) {
            $oObjectsDictionnary = Get-ObjectsDictionnary -ManagementInfo $oMgmtInfo
            # if (-not $oObjectsDictionnary.Filled) {
            #     $oObjectsDictionnary.Fill()
            # }
            $oObjectsDictionnary.AppendDictionary($oResult."objects-dictionary")

            Write-Progress -Activity "Set-NatRuleObjects"
            foreach ($oRuleObject in $oResult.rulebase) {
                if ($oRuleObject.rulebase -ne $null) {
                    if ($oRuleObject.rulebase.Count -gt 0) {
                        foreach ($oRule in $oRuleObject.rulebase) {
                            Set-NatRuleObjects $oRule $oObjectsDictionnary -ManagementInfo $oMgmtInfo
                        }    
                    }
                } else {
                    if ($oRuleObject.Type -eq "nat-rule") {
                        Set-NatRuleObjects $oRuleObject $oObjectsDictionnary -ManagementInfo $oMgmtInfo
                    }
                }
            }
            Write-Progress -Activity "Set-NatRuleObjects" -Completed
            Write-Progress -Activity "Set-NatType"
            foreach ($oRuleObject in $oResult.rulebase) {
                if ($oRuleObject.rulebase -ne $null) {
                    if ($oRuleObject.rulebase.Count -gt 0) {
                        foreach ($oRule in $oRuleObject.rulebase) {
                            Set-Property -InputObject $oRule -Name "NatRuleType" -Value (Get-NatRuleType $oRule)
                        }    
                    }
                } else {
                    if ($oRuleObject.Type -eq "nat-rule") {
                        Set-Property -InputObject $oRuleObject -Name "NatRuleType" -Value (Get-NatRuleType $oRuleObject)
                    }
                }
            }
            Write-Progress -Activity "Set-NatType" -Completed
        }
        return $oResult
    }
}

function Set-NatRuleObjects {
    <#
    .SYNOPSIS
        Replaces UID references in a NAT rule with full object representations.

    .DESCRIPTION
        Iterates over all source, destination, service, and install-on properties of a NAT rule
        and replaces UID strings with their corresponding objects from the dictionary.
        Groups are recursively expanded.

    .PARAMETER ManagementInfo
        The management server connection object.

    .PARAMETER NatRule
        The NAT rule object whose UID references will be resolved.

    .PARAMETER ObjectsDictionnary
        The objects dictionary used to resolve UIDs to full objects.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [object]$NatRule,
        [Parameter(Mandatory, Position = 1)]
        [object]$ObjectsDictionnary
    )
    function Set-NetRuleObject {
        Param(
            [object]$ManagementInfo,
            [Parameter(Mandatory, Position = 0)]
            [object]$NatRule,
            [Parameter(Mandatory, Position = 1)]
            [string]$Property,
            [Parameter(Mandatory, Position = 2)]
            [object]$ObjectsDictionnary
        )
        $uid = $NatRule.$Property
        $NatRule.$Property = $ObjectsDictionnary.Get($uid)
        if ($NatRule.$Property.type -eq "group") {
            $NatRule.$Property = Get-RecursiveGroupMembers -ManagementInfo $ManagementInfo -uid $uid
        }
    }
    Set-NetRuleObject $NatRule "original-destination" $ObjectsDictionnary -ManagementInfo $ManagementInfo
    Set-NetRuleObject $NatRule "translated-destination" $ObjectsDictionnary -ManagementInfo $ManagementInfo
    Set-NetRuleObject $NatRule "original-source" $ObjectsDictionnary -ManagementInfo $ManagementInfo
    Set-NetRuleObject $NatRule "translated-source" $ObjectsDictionnary -ManagementInfo $ManagementInfo
    Set-NetRuleObject $NatRule "original-service" $ObjectsDictionnary -ManagementInfo $ManagementInfo
    Set-NetRuleObject $NatRule "translated-service" $ObjectsDictionnary -ManagementInfo $ManagementInfo
    $aGateways = @()
    foreach ($sGateway in $NatRule."install-on") {
        $aGateways += $ObjectsDictionnary.Get($sGateway)
    }
    $NatRule."install-on" = $aGateways
}

# function Get-NatType {
#     Param(
#         [Parameter(Mandatory)]
#         [object]$NatRule
#     )
#     if (Test-IsNoNatRule $NatRule) {
#         return "NoNAT"
#     } elseif ()
# }

function Test-IsNoNatRule {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$NatRule
    )
    return ($NatRule."translated-service".name -eq "Original") `
      -and ($NatRule."translated-source".name -eq "Original") `
      -and ($NatRule."translated-destination".name -eq "Original")
}
