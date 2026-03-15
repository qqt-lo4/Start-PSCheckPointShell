function Invoke-ShowDiag {
    <#
    .SYNOPSIS
        Retrieves hardware diagnostics from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "show diag" via clish on the gateway and parses the output into a
        hashtable of diagnostic key-value pairs (temperature, fan speed, power supply, etc.).

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .OUTPUTS
        [Hashtable] Diagnostic information as key-value pairs.

    .EXAMPLE
        Invoke-ShowDiag -Firewall "GW01"

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
    $oCommandResult = Invoke-CpridutilClish -ManagementInfo $ManagementInfo -Firewall $Firewall -Script "show diag" -WaitProgressMessage $WaitProgressMessage
    $aCommandResultLines = $oCommandResult.Split("`r`n")
    $aProperties = Select-LineRange -InputArray $aCommandResultLines -StartRegex "^-+$" -IncludeStartLine $false -EndRegex "^-+$" -IncludeEndLine $false
    return $aProperties | Convert-StringArrayToHashtable
}