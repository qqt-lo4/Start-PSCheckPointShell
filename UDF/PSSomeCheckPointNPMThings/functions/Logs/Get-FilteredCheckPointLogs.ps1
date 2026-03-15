function Get-FilteredCheckPointLogs {
    <#
    .SYNOPSIS
        Retrieves and filters Check Point logs using a custom filter function.

    .DESCRIPTION
        Queries all pages of Check Point logs matching a filter expression and time frame,
        then applies a custom scriptblock to each log entry. Only entries where the
        scriptblock returns a non-null value are included in the results.

    .PARAMETER server
        The IP address or hostname of the Check Point management server.

    .PARAMETER port
        The port number for the Web API (1-65535).

    .PARAMETER session
        The Check Point session ID for authentication.

    .PARAMETER filter
        The log filter expression.

    .PARAMETER timeframe
        A timeFrame object defining the time range for the query.

    .PARAMETER ignoreSSLError
        When specified, disables SSL certificate validation.

    .PARAMETER filterFunction
        A scriptblock that receives each log entry and returns a transformed object or $null to skip.

    .OUTPUTS
        System.Object[]. The filtered and transformed log entries.

    .EXAMPLE
        Get-FilteredCheckPointLogs -server "mgmt" -port 443 -session $sid -filter "action:Drop" -timeframe $tf -filterFunction { param($log) if ($log.src -eq "10.0.0.1") { $log } }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$server,
        [Parameter(Mandatory, Position = 1)]
        [ValidateRange(1,65535)]
        [int]$port,
        [Parameter(Mandatory, Position = 2)]
        [string]$session,
        [Parameter(Mandatory, Position = 3)]
        [string]$filter,
        [Parameter(Mandatory, Position = 4)]
        [timeFrame]$timeframe,
        [switch]$ignoreSSLError,
        [scriptblock]$filterFunction
    )

    $result = @()

    $query = Get-CheckPointLogs -server $server -port $port -session $session -filter $query_filter -timeframe $query_timeframe
    if ($query.Content) {
        $logPage = $query.Content | ConvertFrom-Json
        while ($logPage.'logs-count' -ne 0) {
            foreach ($logitem in $logPage.logs) {
                $newitem = Invoke-Command -ScriptBlock $filterFunction -ArgumentList $logitem
                if ($null -ne $newitem) {
                    $result += $newItem
                }
            }    
            $queryId = ($query.Content | ConvertFrom-Json)."query-id"
            $query = Get-CheckPointLogs -server $server -port $port -session $session -queryId $queryId
            $logPage = $query.Content | ConvertFrom-Json
        }
    }

    return $result
}