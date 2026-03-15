function Invoke-Cpridutil {
    <#
    .SYNOPSIS
        Executes a command on a Check Point gateway remotely using cprid_util.

    .DESCRIPTION
        Runs a shell command (bash or clish) on a remote Check Point gateway via the Management API
        run-script mechanism. If the gateway is the management server itself, the command is executed
        locally. Supports long output mode for commands that produce large results, using a temporary
        file transfer mechanism.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name to execute the command on.

    .PARAMETER Shell
        Shell to use for command execution: "bash" or "clish".

    .PARAMETER Script
        The command or script to execute on the gateway.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting for the command to complete.

    .PARAMETER Timeout
        Maximum wait time in seconds for the command to complete. Default: 60.

    .PARAMETER LongOutput
        When specified, uses a file-based mechanism to handle commands with large output
        that would otherwise be truncated by the standard run-script mechanism.

    .OUTPUTS
        [PSCustomObject] Task result object from the Management API run-script command.

    .EXAMPLE
        Invoke-Cpridutil -Firewall "GW01" -Shell "bash" -Script "fw stat"

    .EXAMPLE
        Invoke-Cpridutil -Firewall "GW01" -Shell "clish" -Script "show route" -LongOutput

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
        [Parameter(Mandatory, ParameterSetName = "shell")]
        [string]$Shell,
        [Parameter(Mandatory, ParameterSetName = "shell")]
        [Parameter(Mandatory, ParameterSetName = "long")]
        [string]$Script,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60,
        [Parameter(ParameterSetName = "long")]
        [switch]$LongOutput
    )
    $oFirewall, $oMgmtInfo = Get-GatwayAndManagementFromCache -Firewall $Firewall -ManagementInfo $ManagementInfo
    if ($oFirewall) {
        $sFirewallIP = $oFirewall."ipv4-address"
        if ($LongOutput) {
            $sTaskName = "Invoke-CpridutilLongOutput $($ManagementInfo.Username)"
            $sFileName = "cprid_util_$(Get-Date -Format "yyy-MM-dd_HH-mm-ss")"
            $sScriptToRun = @"
echo '#!/bin/bash' > /tmp/$sFileName.sh
echo '$Script > /tmp/$sFileName.txt' >> /tmp/$sFileName.sh
cprid_util putfile -server $sFirewallIP -local_file /tmp/$sFileName.sh -remote_file /tmp/$sFileName.sh -perms 0755
cprid_util -server $sFirewallIP -verbose rexec -rcmd /tmp/$sFileName.sh
cprid_util getfile -server $sFirewallIP -local_file /tmp/$sFileName.txt -remote_file /tmp/$sFileName.txt
cat /tmp/$sFileName.txt
rm /tmp/$sFileName.txt
"@ 
            #Write-Host $sScriptToRun
            $oResult = Invoke-RunScript -ManagementInfo $oMgmtInfo -script-type 'one time' -script-name $sTaskName -script $sScriptToRun -WaitProgressMessage $WaitProgressMessage -timeout $Timeout
        } else {
            $sTaskName = "Invoke-Cpridutil$Shell $($ManagementInfo.Username)"
            $sCommand = if ($sFirewallIP -eq $oMgmtInfo.Object."ipv4-address") {
                if ($Shell -eq "clish") {
                    "clish -c ""$Script"""
                } else {
                    $Script
                }
            } else {
                "cprid_util -server $sFirewallIP -verbose rexec -rcmd $Shell -c ""$Script"""
            }
            $oResult = Invoke-RunScript -ManagementInfo $oMgmtInfo -script-type 'one time' -script-name $sTaskName -script $sCommand -WaitProgressMessage $WaitProgressMessage -timeout $Timeout
        }
        return $oResult            
    } else {
        throw "Gateway not found ($Firewall)"
    }
}