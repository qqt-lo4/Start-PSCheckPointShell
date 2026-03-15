function Get-ObjectsDictionnary {
    <#
    .SYNOPSIS
        Creates or retrieves a cached dictionary of Check Point objects for efficient UID-based lookups.

    .DESCRIPTION
        Builds a hashtable indexed by UID from the objects dictionary returned by API calls,
        enabling fast object resolution without repeated API queries.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Fill
        When specified, populates the dictionary from the management database.

    .OUTPUTS
        [Hashtable] Dictionary of objects indexed by UID.

    .EXAMPLE
        $dict = Get-ObjectsDictionnary -Fill

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [switch]$Fill
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    if ($oMgmtInfo.Dictionary) {
        if (-not ($oMgmtInfo.Dictionary.Filled) -and $Fill) {
            $oMgmtInfo.Dictionary.Fill()
        }
        return $oMgmtInfo.Dictionary
    } else {
        $oResult = [pscustomobject]@{
            Management = $oMgmtInfo
            InternalDictionary = @{}
            Filled = $false
        }
        $oResult | Add-Member -MemberType ScriptMethod -Name "Fill" -Value {
            $aCPObjects = Get-Objects -ManagementInfo $this.Management `
                                -details-level full `
                                -All -dereference-group-members `
                                -limit 500 `
                                -WriteProgressMessage "Getting $($this.Management.Address) objects"
            foreach ($oObject in $aCPObjects) {
                if ($oObject.uid) {
                    $this.InternalDictionary[$oObject.uid] = $oObject
                }
            }
            $this.Filled = $true
        }

        $oResult | Add-Member -MemberType ScriptMethod -Name "Get" -Value {
            Param(
                [Parameter(Mandatory)]
                [string]$Uid
            )
            $oResult = $this.InternalDictionary[$Uid]
            if ($oResult) {
                return $oResult
            } else {
                $oNewResult = Get-Object -ManagementInfo $this.Management -uid $Uid -details-level full
                if ($oNewResult) {
                    $this.InternalDictionary[$uid] = $oNewResult
                    return $oNewResult
                } else {
                    return $null
                }
            }
        }

        $oResult | Add-Member -MemberType ScriptMethod -Name "AppendDictionary" -Value {
            Param(
                [Parameter(Mandatory)]
                [object]$Dictionary
            )
            if ($Dictionary -is [array]) {
                foreach ($oObject in $Dictionary) {
                    if ($oObject.uid) {
                        $this.InternalDictionary[$oObject.uid] = $oObject
                    }
                }
            } elseif (($Dictionary -is [hashtable]) -or ($Dictionary -is [System.Collections.Specialized.OrderedDictionary])) {
                foreach ($sKey in $Dictionary.Keys) {
                    $oObject = $Dictionary[$sKey]
                    if ($oObject.uid) {
                        $this.InternalDictionary[$oObject.uid] = $uid
                    }
                }
            } else {
                throw "incompatible dictionary type"
            }
        }

        if ($Fill) {
            $oResult.Fill()
        }
        $oMgmtInfo.Dictionary = $oResult

        return $oResult
    }
}