function Save-ManagementFile {
    <#
    .SYNOPSIS
        Downloads a file from the Check Point Management server to a local folder.

    .DESCRIPTION
        Transfers a file (binary or text) from the Management server to a local destination
        using a chunked base64 mechanism via the run-script API.

        The file is first converted to base64 on the management server, then downloaded
        in chunks of 100KB to avoid the run-script response size limit, and finally
        decoded and written locally.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER RemotePath
        Full path of the file on the management server.

    .PARAMETER FolderPath
        Local destination folder. Must exist.

    .PARAMETER FileName
        Optional local file name. If not specified, the original file name is used.

    .PARAMETER ChunkSize
        Size of each download chunk in bytes. Default: 100000 (100KB).

    .PARAMETER Timeout
        Maximum wait time in seconds per run-script call. Default: 120.

    .PARAMETER CleanupRemote
        If specified, deletes the remote file after successful download.

    .OUTPUTS
        [System.IO.FileInfo] The downloaded local file.

    .EXAMPLE
        Save-ManagementFile -RemotePath "/tmp/show_package.tar.gz" -FolderPath "C:\Exports"

    .EXAMPLE
        Save-ManagementFile -RemotePath "/var/log/messages" -FolderPath "C:\Logs" -FileName "messages.log"

    .EXAMPLE
        Save-ManagementFile -RemotePath "/tmp/export.tar.gz" -FolderPath "C:\Temp" -CleanupRemote

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-16) - Initial version
    #>
    [CmdletBinding()]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,

        [Parameter(Mandatory)]
        [string]$RemotePath,

        [Parameter(Mandatory)]
        [string]$FolderPath,

        [string]$FileName,

        [ValidateRange(1024, 1000000)]
        [int]$ChunkSize = 100000,

        [ValidateRange(1, 3600)]
        [int]$Timeout = 120,

        [switch]$CleanupRemote
    )

    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }

    Process {
        if (-not (Test-Path $FolderPath -PathType Container)) {
            throw "Folder does not exist: $FolderPath"
        }

        $sProgressActivity = "Downloading $RemotePath"

        # Convert file to base64 on the management server and get the file size
        $sBase64File = "${RemotePath}.b64"
        $sPrepareScript = "base64 '$RemotePath' > '$sBase64File' && stat -c%s '$sBase64File'"
        Write-Progress -Activity $sProgressActivity -Status "Preparing base64 file..." -PercentComplete 0
        $oPrepareResult = Invoke-RunScript -ManagementInfo $oMgmtInfo `
            -script $sPrepareScript `
            -targets $oMgmtInfo.Object.name `
            -timeout $Timeout `
            -script-type 'one time' `
            -script-name "Save-ManagementFile b64"

        if ($oPrepareResult.status -ne "succeeded") {
            Write-Progress -Activity $sProgressActivity -Completed
            throw "Save-ManagementFile failed: could not prepare file for transfer from $RemotePath`n$($oPrepareResult.'task-result')"
        }

        $iFileSize = [long]($oPrepareResult."task-result").Trim()
        $iChunks = [Math]::Ceiling($iFileSize / $ChunkSize)

        # Download in chunks using dd (byte-level offset/count)
        $aBase64Chunks = @()
        for ($iChunk = 0; $iChunk -lt $iChunks; $iChunk++) {
            $iSkip = $iChunk * $ChunkSize
            $iCount = [Math]::Min($ChunkSize, $iFileSize - $iSkip)
            $iPercent = [Math]::Round(($iChunk / $iChunks) * 100)

            Write-Progress -Activity $sProgressActivity `
                -Status "Chunk $($iChunk + 1)/$iChunks ($([Math]::Round($iSkip / 1KB))KB / $([Math]::Round($iFileSize / 1KB))KB)" `
                -PercentComplete $iPercent

            $sChunkScript = "dd if='$sBase64File' bs=1 skip=$iSkip count=$iCount 2>/dev/null"
            $oChunkResult = Invoke-RunScript -ManagementInfo $oMgmtInfo `
                -script $sChunkScript `
                -targets $oMgmtInfo.Object.name `
                -timeout $Timeout `
                -script-type 'one time' `
                -script-name "Save-ManagementFile chunk $($iChunk + 1)/$iChunks"

            if ($oChunkResult.status -ne "succeeded") {
                Write-Progress -Activity $sProgressActivity -Completed
                # Cleanup base64 temp file before throwing
                Invoke-RunScript -ManagementInfo $oMgmtInfo `
                    -script "rm -f '$sBase64File'" `
                    -targets $oMgmtInfo.Object.name `
                    -timeout 30 `
                    -script-type 'one time' `
                    -script-name "Save-ManagementFile cleanup" | Out-Null
                throw "Save-ManagementFile failed: download error on chunk $($iChunk + 1)/$iChunks"
            }

            $aBase64Chunks += $oChunkResult."task-result"
        }

        # Cleanup the temporary base64 file on the management server
        Write-Progress -Activity $sProgressActivity -Status "Cleaning up remote files..." -PercentComplete 100
        $sCleanupScript = "rm -f '$sBase64File'"
        if ($CleanupRemote) {
            $sCleanupScript += "; rm -f '$RemotePath'"
        }
        Invoke-RunScript -ManagementInfo $oMgmtInfo `
            -script $sCleanupScript `
            -targets $oMgmtInfo.Object.name `
            -timeout 30 `
            -script-type 'one time' `
            -script-name "Save-ManagementFile cleanup" | Out-Null

        # Reassemble and decode locally
        if (-not $FileName) {
            $FileName = [System.IO.Path]::GetFileName($RemotePath)
        }
        $sLocalFilePath = Join-Path $FolderPath $FileName

        $sBase64Content = ($aBase64Chunks -join "") | Remove-EmptyString -TrimOnly
        $aBytes = [System.Convert]::FromBase64String(($sBase64Content -join ""))
        [System.IO.File]::WriteAllBytes($sLocalFilePath, $aBytes)

        Write-Progress -Activity $sProgressActivity -Completed

        return Get-Item $sLocalFilePath
    }
}
