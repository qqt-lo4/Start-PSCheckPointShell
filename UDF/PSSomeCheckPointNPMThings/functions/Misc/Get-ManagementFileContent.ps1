function Get-ManagementFileContent {
    <#
    .SYNOPSIS
        Retrieves the content of a text file from the Check Point Management server.

    .DESCRIPTION
        Uses the run-script API to read file content from the Management server.
        Supports Check Point environment variable expansion ($FWDIR, $CPDIR, etc.).

    .PARAMETER ManagementInfo
        The Management connection object (returned by Connect-ManagementAPI).

    .PARAMETER Path
        The path of the file to retrieve. Supports variables like $FWDIR, $CPDIR, etc.

    .PARAMETER Timeout
        Timeout in seconds for script execution. Default is 60.

    .OUTPUTS
        String. The file content.

    .EXAMPLE
        Get-ManagementFileContent -ManagementInfo $mgmt -Path "/var/log/messages"

    .EXAMPLE
        Get-ManagementFileContent -ManagementInfo $mgmt -Path '$FWDIR/conf/objects_5_0.C'

    .EXAMPLE
        $content = Get-ManagementFileContent -Path '$CPDIR/registry/HKLM_registry.data'

    .NOTES
        Author  : Assistant
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,

        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        [ValidateRange(1, 3600)]
        [int]$Timeout = 60
    )

    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
    }

    Process {
        # Build bash script to read the file
        # Using eval to allow variable expansion ($FWDIR, $CPDIR, etc.)
        $sScript = @"
#!/bin/bash
FILE_PATH=`$(eval echo "$Path")
if [[ -f "`$FILE_PATH" ]]; then
    cat "`$FILE_PATH"
else
    echo "ERROR_FILE_NOT_FOUND: `$FILE_PATH" >&2
    exit 1
fi
"@

        # Execute script on the Management server
        $oResult = Invoke-RunScript -ManagementInfo $oMgmtInfo `
            -script $sScript `
            -targets $oMgmtInfo.Object.name `
            -timeout $Timeout `
            -script-type 'one time' `
            -script-name "Reading management file" `
            -WaitProgressMessage "Reading file $Path"

        # Check result
        $sTaskResponse = $oResult."task-result"

        if ($sTaskResponse -match "^ERROR_FILE_NOT_FOUND:") {
            throw "File '$Path' does not exist on the Management server."
        }

        if ($oResult.status -ne "succeeded") {
            throw "Error reading file: $($oResult.'task-details'.statusDescription)"
        }

        return $sTaskResponse
    }
}
