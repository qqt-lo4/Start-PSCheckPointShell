function Export-CPSecurityPolicy {
    <#
    .SYNOPSIS
        Exports a Check Point security policy package into a human-readable format (HTML/JSON).

    .DESCRIPTION
        Executes the "Show Package Tool" ($MDS_FWDIR/scripts/web_api_show_package.sh) on the
        Check Point Management Server to export a security policy package as a compressed
        .tar.gz file containing HTML and JSON representations of the rulebase and objects.

        The generated archive is then downloaded locally via a base64 transfer mechanism
        using run-script.

        Reference: sk120342

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER PolicyPackage
        Name or UID of the security policy package to export.
        If not specified, all installed policy packages are exported.

    .PARAMETER Domain
        On a Multi-Domain Security Management Server, specifies the Domain.
        Accepts: IP address of the CMA, Domain object name, or Domain UUID.

    .PARAMETER IgnoreCertificate
        Uses the -b flag to ignore certificate verification (UNSAFE).
        Required when the API server fingerprint has not been approved.

    .PARAMETER OutputPath
        Remote output path on the management server for the .tar.gz file.
        Default: /tmp

    .PARAMETER FolderPath
        Local destination folder to download the exported .tar.gz file. Must exist.
        If not specified, the file remains on the management server only.

    .PARAMETER Timeout
        Maximum wait time in seconds for the export task to complete. Default: 600.

    .OUTPUTS
        [System.IO.FileInfo] The downloaded TGZ file (if FolderPath is specified).
        [String] The remote file path on the management server (if FolderPath is not specified).

    .EXAMPLE
        Export-CPSecurityPolicy -PolicyPackage "Standard" -IgnoreCertificate -FolderPath "C:\Exports"

        Exports the "Standard" policy package (ignoring cert verification) and downloads the TGZ locally.
        Output file: show_package_Standard_2026-03-16_16-03-04.tar.gz

    .EXAMPLE
        Export-CPSecurityPolicy -FolderPath "C:\Exports"

        Exports all installed policy packages and downloads the TGZ locally.

    .EXAMPLE
        Export-CPSecurityPolicy -PolicyPackage "Standard" -Domain "MyDomain"

        Exports the "Standard" policy from a specific domain (MDS environment).
        The file remains on the management server.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-16) - Initial version
    #>
    [CmdletBinding()]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,

        [string]$PolicyPackage,

        [string]$Domain,

        [switch]$IgnoreCertificate,

        [string]$OutputPath = "/tmp",

        [string]$FolderPath,

        [ValidateRange(1, 3600)]
        [int]$Timeout = 600
    )

    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }

    Process {
        if ($FolderPath -and -not (Test-Path $FolderPath -PathType Container)) {
            throw "Folder does not exist: $FolderPath"
        }

        # Build the output file path including the policy package name
        $sTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        if ($PolicyPackage) {
            $sSafePackageName = $PolicyPackage -replace '[^\w\-\.]', '_'
            $sOutputFile = "$OutputPath/show_package_${sSafePackageName}_${sTimestamp}.tar.gz"
        } else {
            $sOutputFile = "$OutputPath/show_package_all_${sTimestamp}.tar.gz"
        }

        # Build the web_api_show_package.sh command arguments
        $sArgs = @()
        if ($PolicyPackage) {
            $sArgs += "-k '$PolicyPackage'"
        }
        if ($Domain) {
            $sArgs += "-d '$Domain'"
        }
        if ($IgnoreCertificate) {
            $sArgs += "-b"
        }
        $sArgs += "-o '$sOutputFile'"

        $sCommand = "`$MDS_FWDIR/scripts/web_api_show_package.sh $($sArgs -join ' ')"

        # Wrap in a script that checks the result
        $sScript = @"
#!/bin/bash
$sCommand 2>&1
RC=`$?
if [ `$RC -ne 0 ]; then
    exit `$RC
fi
# Verify the generated file is not empty (> 1KB)
FILESIZE=`$(stat -c%s '$sOutputFile' 2>/dev/null || echo 0)
if [ "`$FILESIZE" -lt 1024 ]; then
    echo "EXPORT_ERROR:Generated file is too small (`${FILESIZE} bytes), export likely failed"
    exit 1
fi
echo "EXPORT_FILE_PATH:$sOutputFile"
"@

        # Execute on the management server
        $oResult = Invoke-RunScript -ManagementInfo $oMgmtInfo `
            -script $sScript `
            -targets $oMgmtInfo.Object.name `
            -timeout $Timeout `
            -script-type 'one time' `
            -script-name "Export-CPSecurityPolicy" `
            -WaitProgressMessage "Exporting policy package$(if ($PolicyPackage) { " '$PolicyPackage'" } else { ' (all)' })"

        $sTaskOutput = $oResult."task-result"

        # Check for specific error patterns and give actionable messages
        if ($sTaskOutput -match "Fingerprint wasn't approved") {
            throw "Export-CPSecurityPolicy failed: API fingerprint not approved.`nUse -IgnoreCertificate to bypass certificate verification.`n$sTaskOutput"
        }

        if ($sTaskOutput -match "EXPORT_ERROR:(.+)") {
            throw "Export-CPSecurityPolicy failed: $($Matches[1].Trim())"
        }

        # Extract the file path from the output
        $sRemoteFilePath = if ($sTaskOutput -match "EXPORT_FILE_PATH:(.+)") {
            $Matches[1].Trim()
        } else {
            throw "Export-CPSecurityPolicy failed: export did not complete successfully.`n$sTaskOutput"
        }

        if (-not $FolderPath) {
            return $sRemoteFilePath
        }

        # Download the exported file using chunked base64 transfer
        return Save-ManagementFile -ManagementInfo $oMgmtInfo `
            -RemotePath $sRemoteFilePath `
            -FolderPath $FolderPath `
            -Timeout $Timeout
    }
}
