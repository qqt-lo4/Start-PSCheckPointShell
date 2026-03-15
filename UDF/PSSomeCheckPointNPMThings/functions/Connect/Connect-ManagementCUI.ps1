function Connect-ManagementCUI {
    <#
    .SYNOPSIS
        Interactively connects to one or more Check Point management servers.

    .DESCRIPTION
        Prompts the user for credentials via a CLI dialog and connects to each specified
        management server. Skips servers that are already connected. After connection,
        registers PowerShell argument completers for Firewall and ManagementInfo parameters.

    .PARAMETER ManagementAddress
        An array of management server addresses (hostname or IP, optionally with port).

    .PARAMETER Port
        The default port number for the Web API. Defaults to 4434.

    .OUTPUTS
        None. Connections are stored in global variables ($Global:CPManagement, $Global:CPManagementHashtable).

    .EXAMPLE
        Connect-ManagementCUI -ManagementAddress "mgmt1.example.com", "mgmt2.example.com"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ManagementAddress,
        [int]$Port = 4434
    )
    if ($null -eq $Global:CPManagement) { $Global:CPManagement = @() }
    if ($null -eq $Global:CPManagementHashtable) { $Global:CPManagementHashtable = @{} }

    $aManagementToConnect = @()
    foreach ($sManagement in $ManagementAddress) {
        if ($sManagement -notin $Global:CPManagement.Object.name) {
            $aManagementToConnect += $sManagement
        }
    }

    foreach ($sManagement in $aManagementToConnect) {
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
        # Connect to management, will autoregister in global variables
        $hManagement = Select-StringMatchingGroup -InputString $sManagement -Regex (Get-HostPortRegex -FullLine) -OnlyGroups @("Host", "Port")
        if ($hManagement.Port) {
            $hManagement.Port = [int]$hManagement.Port
        } else {
            $hManagement.Port = $Port
        }
        Connect-ManagementAPI -Address $hManagement.Host -Port $hManagement.Port -Credential $oCPCred -ignoreSSLError | Out-Null
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
