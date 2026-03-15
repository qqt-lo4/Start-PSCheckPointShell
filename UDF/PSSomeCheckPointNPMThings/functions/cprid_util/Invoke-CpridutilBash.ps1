function Invoke-CpridutilBash {
    <#
    .SYNOPSIS
        Executes a bash command on a Check Point gateway via cprid_util.

    .DESCRIPTION
        Wrapper around Invoke-Cpridutil that executes a bash command on a remote gateway.
        Automatically parses the output: attempts JSON conversion first, then regex matching
        if a pattern is provided, otherwise returns the raw string. Throws an error if the
        task fails or SIC communication is broken.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name to execute the command on.

    .PARAMETER Script
        The bash command to execute on the gateway.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting for the command to complete.

    .PARAMETER Timeout
        Maximum wait time in seconds for the command to complete. Default: 60.

    .PARAMETER Regex
        Optional regex pattern to apply to the output. Named groups are returned as a hashtable.

    .PARAMETER FilterLines
        Optional scriptblock to filter output lines before processing.

    .OUTPUTS
        [PSCustomObject] JSON-parsed output, [Hashtable] regex matches, or [String] raw output.

    .EXAMPLE
        Invoke-CpridutilBash -Firewall "GW01" -Script "fw stat"

    .EXAMPLE
        Invoke-CpridutilBash -Firewall "GW01" -Script "fw ver" -Regex "Build (?<build>[0-9]+)"

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
        [Parameter(Mandatory)]
        [string]$Script,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [string]$Regex,
        [scriptblock]$FilterLines
    )
    $oCpridutilResult = Invoke-Cpridutil -ManagementInfo $ManagementInfo -Firewall $Firewall -Shell "bash" -Script $Script -WaitProgressMessage $WaitProgressMessage -Timeout $Timeout
    $sCaller = (Get-PSCallStack)[1].Command
    $oResult = $oCpridutilResult."task-result" | Remove-EmptyString -TrimOnly
    if ($FilterLines) {
        $oResult = $oResult | Where-Object $FilterLines
    }
    if ($oCpridutilResult.status -eq "succeeded") {
        $sResult = $oResult -join "`n"
        try {
            return $sResult | ConvertFrom-Json
        } catch {
            if ($Regex) {
                $oSS = Select-String -InputObject $sResult -Pattern $Regex -AllMatches
                return $oSS | Convert-MatchInfoToHashtable -ExcludeNumbers
            } else {
                return $sResult
            }
        }
    } else {
        $exception = if ($oResult -eq "(NULL BUF)") {
            New-Object System.Exception("$sCaller failed: SIC commmunication failed")
        } else {
            New-Object System.Exception("$sCaller failed: $($oCpridutilResult.'task-result')")
        }
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            '$sCaller',
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            $oCpridutilResult
        )
        throw $errorRecord
    }
}
