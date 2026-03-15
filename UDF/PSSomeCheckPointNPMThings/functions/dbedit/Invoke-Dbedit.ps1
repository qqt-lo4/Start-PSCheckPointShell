function Invoke-DBedit {
    <#
    .SYNOPSIS
        Executes dbedit commands on the Check Point management server.

    .DESCRIPTION
        Runs one or more dbedit commands on the management server via the run-script API.
        Dbedit provides low-level access to the Check Point object database.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [String] Command output from dbedit.

    .EXAMPLE
        Invoke-DBedit -Commands "print network_objects GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding()]
    Param(
        [object]$ManagementInfo,
        
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Commands,
        
        [ValidateRange(0, [int]::MaxValue)]
        [int]$timeout = 120,
        
        [AllowNull()]
        [string]$WaitProgressMessage = "Executing dbedit commands..."
    )
    
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    }
    
    Process {
        # Construire le script dbedit
        $aScriptLines = @()
        
        # Traiter les commandes fournies
        foreach ($command in $Commands) {
            if (-not [string]::IsNullOrWhiteSpace($command)) {
                # Vérifier si la commande contient des retours à la ligne
                if ($command -match '[\r\n]') {
                    # Splitter sur les retours à la ligne
                    $lines = $command -split '[\r\n]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                    foreach ($line in $lines) {
                        $aScriptLines += $line.Trim()
                    }
                } else {
                    $aScriptLines += $command.Trim()
                }
            }
        }
        
        # S'assurer que la dernière ligne est "quit"
        if ($aScriptLines.Count -eq 0 -or $aScriptLines[-1] -ne "quit") {
            $aScriptLines += "quit"
        }
        
        # Créer le script avec heredoc (méthode 3)
        $sScript = @"
dbedit -local << 'EOF'
$($aScriptLines -join "`n")
EOF
"@
        
        # Paramètres pour Invoke-RunScript
        $hParams = @{
            "Script-Name"       = "dbedit from $($oMgmtInfo.Username)"
            ManagementInfo      = $oMgmtInfo
            'script-type'       = "one time"
            script              = $sScript
            timeout             = $timeout
            WaitProgressMessage = $WaitProgressMessage
        }
        
        # Exécuter via run-script (la target sera automatiquement le management)
        $oResult = Invoke-RunScript @hParams
    }
    
    End {
        $sResult = ($oResult."task-result" ).Split("`r`n")
        return Select-LineRange -InputArray $sResult -StartRegex "dbedit>.*" -EndRegex "dbedit>.*" -IncludeStartLine:$false -IncludeEndLine:$false
    }
}
