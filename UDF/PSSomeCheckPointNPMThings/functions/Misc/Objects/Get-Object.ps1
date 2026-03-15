function Get-Object {
    <#
    .SYNOPSIS
        Retrieves a generic object from the Check Point management database by UID or name.

    .DESCRIPTION
        Returns any object type from the management database. Supports retrieval by UID
        or name, with optional group membership information.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER uid
        UID of the object to retrieve.

    .PARAMETER name
        Name of the object to retrieve.

    .PARAMETER GetMemberOf
        Include the list of groups this object belongs to.

    .OUTPUTS
        [PSCustomObject] The requested object.

    .EXAMPLE
        Get-Object -name "WebServer01"

    .EXAMPLE
        Get-Object -uid "abc123" -GetMemberOf

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "uid")]
        [string]$uid,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "name")]
        [string]$name,
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard",
        [switch]$GetMemberOf
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }
    Process {
        if ($uid) {
            $body = @{
                uid = $uid
                "details-level" = ${details-level}
            }
            $oByUid = $oMgmtInfo.CallAPI("show-object", $body)
            $oResult = ($oByUid).object
            if ($GetMemberOf) {
                $hArgs = @{
                    ManagementInfo = $oMgmtInfo
                    uid = $oResult.uid
                    "details-level" = "full"
                }
                switch ($oResult.type) {
                    "host" {
                        return Get-HostObject @hArgs
                    }
                    "address-range" {
                        return Get-AddressRange @hArgs
                    }
                    "group" {
                        return Get-NetworkGroup @hArgs
                    }
                    "network" {
                        return Get-NetworkObject @hArgs
                    }
                    default {
                        return $oResult
                    }
                }
            } else {
                return $oResult
            }    
        } else {
            #name was provided
            $aObjects = Get-Objects -ManagementInfo $oMgmtInfo -filter $name -details-level full
            if ($aObjects.total -gt 0) {
                $oResult = $aObjects.objects | Where-Object { $_.name -eq $name }
                if ($oResult) {
                    return Get-Object -ManagementInfo $oMgmtInfo -uid $oResult.uid -details-level full
                } else {
                    return $null
                }
            } else {
                return $null
            }
        }
    }
}