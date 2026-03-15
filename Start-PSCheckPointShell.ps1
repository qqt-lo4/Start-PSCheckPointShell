Param(
    [string]$InputDir
)

$iModulesCount = 7
$i = 0

#region Includes
Write-Progress -Activity "Loading script modules" -Status "PSSomeAPIThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeAPIThings
Write-Progress -Activity "Loading script modules" -Status "PSSomeCheckPointNPMThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeCheckPointNPMThings -WarningAction SilentlyContinue
Write-Progress -Activity "Loading script modules" -Status "PSSomeCLIThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeCLIThings
Write-Progress -Activity "Loading script modules" -Status "PSSomeCoreThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeCoreThings
Write-Progress -Activity "Loading script modules" -Status "PSSomeDataThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeDataThings
Write-Progress -Activity "Loading script modules" -Status "PSSomeFileThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeFileThings
Write-Progress -Activity "Loading script modules" -Status "PSSomeNetworkThings" -PercentComplete (($($i++; $i) / $iModulesCount) * 100)
Import-Module $PSScriptRoot\UDF\PSSomeNetworkThings
Write-Progress -Activity "Loading script modules" -Status "Loading end" -PercentComplete 100 -Completed
#endregion Includes

#region script info
#scriptVersion=1.0
#endregion script info

$sConfigFilePath = Get-RootScriptConfigFile
$config = if ($sConfigFilePath -ne "" -and (Test-Path $sConfigFilePath -PathType Leaf)) {
    Get-Content -Path $sConfigFilePath | ConvertFrom-Json
} else {
    $sConfigFilePath = (Get-ScriptDir -InputDir) + "\config.json"
    [pscustomobject]@{ Managements = @() }
}

function Save-Config {
    <#
    .SYNOPSIS
        Saves the current configuration to the config file.

    .DESCRIPTION
        Overwrites the "Managements" key in the config file with the list of currently
        connected management servers (from $Global:CPManagement) in "address:port" format,
        so the file exactly reflects the loaded state. Any other properties already present
        in the file are preserved.

    .EXAMPLE
        Save-Config
    #>
    $oConfig = if (Test-Path $sConfigFilePath) {
        Get-Content -Path $sConfigFilePath -Raw | ConvertFrom-Json
    } else {
        [pscustomobject]@{}
    }
    $oConfig | Add-Member -NotePropertyName "Managements" -NotePropertyValue @(
        $Global:CPManagement | ForEach-Object { "$($_.Address):$($_.Port)" }
    ) -Force
    $oConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $sConfigFilePath -Encoding UTF8
    Write-Host "Configuration saved to $sConfigFilePath" -ForegroundColor Green
}

Write-Host "----------------------------" -ForegroundColor Cyan
Write-Host "Check Point PowerShell Shell" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan
Write-Host ""

if ($config.Managements -and $config.Managements.Count -gt 0) {
    Connect-ManagementCUI -ManagementAddress $config.Managements -Port 4434
} else {
    Write-Host "No management server configured." -ForegroundColor Yellow
    Write-Host ""
}

function Get-CheckPointCommands {
    <#
    .SYNOPSIS
        Lists all available Check Point commands from the PSSomeCheckPointNPMThings module.
    #>
    Get-Command -Module PSSomeCheckPointNPMThings | Sort-Object Name | ForEach-Object {
        $sSynopsis = (Get-Help $_.Name -ErrorAction SilentlyContinue).Synopsis
        [PSCustomObject]@{
            Name     = $_.Name
            Synopsis = if ($sSynopsis -and $sSynopsis -ne $_.Name) { $sSynopsis.Trim() } else { "" }
        }
    } | Format-Table -Property Name, Synopsis -AutoSize -Wrap
}

Write-Host "Some commands:" -ForegroundColor Cyan
Write-Host "  Connect-ManagementCUI   Connect to management servers"
Write-Host "  Save-Config             Save current connections to config file"
Write-Host "  Get-CheckPointCommands  List all available Check Point commands"
Write-Host ""
