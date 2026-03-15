function Update-NetworkGroupFromJson {
    <#
    .SYNOPSIS
        Updates a Check Point network group's members from a JSON data source.

    .DESCRIPTION
        Fetches IP addresses from a JSON URL, optionally filtering with an XPath expression,
        and synchronizes the network group members accordingly (adding new, removing stale).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER JsonPath
        URL to the JSON data source containing IP addresses.

    .PARAMETER Group
        Name of the network group to update.

    .OUTPUTS
        None. Updates the group in the management database.

    .EXAMPLE
        Update-NetworkGroupFromJson -JsonPath "https://api.example.com/ip_ranges.json" -Group "External_IPs"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [string]$JsonPath,
        [string]$XpathFilter,
        [Parameter(Mandatory)]
        [string]$Group
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $oGroup = Get-NetworkGroup -ManagementInfo asfwstago -name $Group
        $sJsonPath = if ($JsonPath) {
            $JsonPath
        } else {
            Get-ObjectTagValue -ManagementInfo $oMgmtInfo -Object $oGroup -TagName "JsonPath"
        }
        if ($null -eq $sJsonPath) {
            throw "Json not provided or not found in group"
        }
        $sXpath = if ($XpathFilter) {
            $XpathFilter
        } else {
            Get-ObjectTagValue -ManagementInfo $oMgmtInfo -Object $oGroup -TagName "XpathFilter"
        }
        if ($null -eq $sXpath) {
            throw "Xpath filter not provided or not found in group"
        }
    }
    Process {
        $aRanges = (Get-FilteredJson -JsonPath $sJsonPath -XPath $sXpath) | Select-Object -Unique
        $aObjects = @()
        $iIndex = 0
        foreach ($sIP in $aRanges) {
            $iPercent = ($iIndex / $aRanges.Count) * 100
            Write-Progress -Activity "Getting Okta Objects" -Status "$sIP" -PercentComplete $iPercent
            Write-Verbose "$sIP in Okta ranges"
            $testObject = Test-CPObject -ManagementInfo $oMgmtInfo -Value $sIP
            if ($testObject) {
                Write-Verbose "$sIP object exists"
                $aObjects += $testObject[0]
            } else {
                Write-Verbose "$sIP needs to be created"
                $oNew = New-CPObject -ManagementInfo $oMgmtInfo -Value $sIP
                Write-Verbose "$sIP new object uid is $($oNew.uid)"
                $aObjects += $oNew
            }
            $iIndex += 1
        }
        Write-Verbose "Updating group $($oGroup.name) ($($oGroup.uid)) to all objects"
        Write-Progress -Activity "Getting Okta Objects" -Status "Updating group $($oGroup.name) ($($oGroup.uid)) to all objects" -PercentComplete 100
        Update-NetworkGroup -ManagementInfo $oMgmtInfo -uid $oGroup.uid -members $aObjects.uid
        Write-Progress -Activity "Getting Okta Objects" -Status "Operation ended" -PercentComplete 100 -Completed
    }
}