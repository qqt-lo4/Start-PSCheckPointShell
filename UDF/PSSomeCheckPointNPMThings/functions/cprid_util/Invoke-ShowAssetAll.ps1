function Invoke-ShowAssetAll {
    <#
    .SYNOPSIS
        Retrieves hardware asset information from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "show asset all" via clish on the gateway and parses the key-value
        output into a hashtable (manufacturer, model, serial number, etc.).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .OUTPUTS
        [Hashtable] Asset information as key-value pairs.

    .EXAMPLE
        Invoke-ShowAssetAll -Firewall "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage
    )
    $oCommandResult = Invoke-CpridutilClish -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "show asset all" -WaitProgressMessage $WaitProgressMessage
    $aCommandResultLines = ($oCommandResult.Split("`r`n"))
    return $aCommandResultLines | Convert-StringArrayToHashtable
}