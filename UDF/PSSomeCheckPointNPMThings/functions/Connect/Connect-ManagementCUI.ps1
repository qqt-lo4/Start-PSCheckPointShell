function Connect-ManagementCUI {
    <#
    .SYNOPSIS
        Interactively connects to one or more Check Point management servers.

    .DESCRIPTION
        Prompts the user for credentials via a CLI dialog and connects to each specified
        management server. Skips servers that are already connected. After connection,
        registers PowerShell argument completers for Firewall and ManagementInfo parameters.

        This function has two behavioural modes depending on how it is invoked:

        CONNECT mode (called as Connect-ManagementCUI):
            All global tracking variables are reset before connecting.
            Use this to start a fresh session.

        ADD mode (called as Add-ManagementCUI, alias of this function):
            Existing connections are preserved; new servers are appended.
            Already-connected servers are skipped automatically.

    .PARAMETER ManagementAddress
        An array of management server addresses (hostname or IP, optionally with port).

    .PARAMETER Port
        The default port number for the Web API. Defaults to 4434.

    .OUTPUTS
        None. Connections are stored in global variables ($Global:CPManagement, $Global:CPManagementHashtable).

    .EXAMPLE
        Connect-ManagementCUI -ManagementAddress "mgmt1.example.com", "mgmt2.example.com"

        Resets all existing connections, then connects to both servers.

    .EXAMPLE
        Add-ManagementCUI -ManagementAddress "mgmt3.example.com"

        Adds mgmt3 to the existing connections without disconnecting mgmt1/mgmt2.

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0

        2.0.0 (2026-03-16) - Add/Connect dual-mode via alias (same pattern as Connect/Add-ManagementAPI)
        1.0.0              - Initial version
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ManagementAddress,
        [int]$Port = 4434
    )
    Begin {
        $aManagements = @()
    }
    Process {
        $aManagements += $ManagementAddress
    }
    End {
        # Detect invocation mode via alias name
        $bCalledAsAdd = $MyInvocation.InvocationName -ne 'Connect-ManagementCUI'

        if (-not $bCalledAsAdd) {
            # Connect mode: reset globals for a fresh session
            $Global:CPManagement          = @()
            $Global:CPManagementHashtable = @{}
        } else {
            # Add mode: ensure globals exist
            if ($null -eq $Global:CPManagement) { $Global:CPManagement = @() }
            if ($null -eq $Global:CPManagementHashtable) { $Global:CPManagementHashtable = @{} }
        }

        # Filter out already-connected servers
        $aManagementToConnect = @()
        foreach ($sManagement in $aManagements) {
            if ($sManagement -notin $Global:CPManagement.Object.name) {
                $aManagementToConnect += $sManagement
            }
        }

        for ($i = 0; $i -lt $aManagementToConnect.Count; $i++) {
            $sManagement = $aManagementToConnect[$i]
            $oCPCred = if ($Global:CPLastCred) {
                Read-CLIDialogCredential -HeaderAppName "Check Point Management $sManagement" -Credential $Global:CPLastCred
            } else {
                Read-CLIDialogCredential -HeaderAppName "Check Point Management $sManagement"
            }
            $Global:CPLastCred = $oCPCred
            if ($null -eq $Global:CPCred) {
                $Global:CPCred = @{}
            }
            $Global:CPCred[$sManagement] = $oCPCred
            # Parse host and port from address string
            $hManagement = Select-StringMatchingGroup -InputString $sManagement -Regex (Get-HostPortRegex -FullLine) -OnlyGroups @("Host", "Port")
            if ($hManagement.Port) {
                $hManagement.Port = [int]$hManagement.Port
            } else {
                $hManagement.Port = $Port
            }
            # First server in Connect mode: use Connect-ManagementAPI to reset globals
            # All other cases: use Add-ManagementAPI to append
            if ($i -eq 0 -and -not $bCalledAsAdd) {
                Connect-ManagementAPI -Address $hManagement.Host -Port $hManagement.Port -Credential $oCPCred -ignoreSSLError | Out-Null
            } else {
                Add-ManagementAPI -Address $hManagement.Host -Port $hManagement.Port -Credential $oCPCred -ignoreSSLError
            }
        }

        # Register argument completers only once, after the first successful connection
        if ($Global:CPManagement.Count -ge 1) {
            Register-ArgumentCompleter -ParameterName Firewall -ScriptBlock {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Global:CPGateway.Name | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Firewall: $_")
                }
            }

            Register-ArgumentCompleter -ParameterName ManagementInfo -ScriptBlock {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Global:CPManagement.Object.Name | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Management: $_")
                }
            }
        }
    }
}

Set-Alias Add-ManagementCUI Connect-ManagementCUI
