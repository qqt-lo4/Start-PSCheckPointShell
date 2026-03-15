function Test-CPObject {
    <#
    .SYNOPSIS
        Tests if a Check Point object exists by name or IP value in the management database.

    .DESCRIPTION
        Checks whether an object with the specified name or IP value already exists.
        Returns the object if found, or $null otherwise.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] The existing object, or $null if not found.

    .EXAMPLE
        Test-CPObject -name "WebServer01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "name")]
        [string]$Name,
        [Parameter(ParameterSetName = "value")]
        [string]$Value
    )
    $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo

    if ($PSCmdlet.ParameterSetName -eq "name") {
        $oResult = Get-Object -ManagementInfo $oMgmtInfo -name $Name
        if ($oResult) {
            return $oResult
        } else {
            return $null
        }
    } else {
        $oIP = Test-StringIsIP -string $Value -Mask32AsHost
        if ($oIP) {
            $sType = switch ($oIP.Type) {
                "Address" { "host" }
                "Range" { "address-range" }
                "Network" { "network" }
            }
            $aResult = Get-Objects -ManagementInfo $oMgmtInfo -filter $oIP.String -type $sType
            if ($sType -eq "Network") {
                return $aResult.objects | Where-Object { $_."mask-length4" -eq $oIP.masklengthv4 }
            } else {
                return $aResult.objects
            }
        }
    }
}