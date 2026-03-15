function Get-CheckPointLogs {
    <#
    .SYNOPSIS
        Retrieves logs from the Check Point management server.

    .DESCRIPTION
        Queries the Check Point show-logs API endpoint. Supports starting a new log query
        with a filter and time frame, or continuing an existing query by its ID.

    .PARAMETER server
        The IP address or hostname of the Check Point management server.

    .PARAMETER port
        The port number for the Web API (1-65535).

    .PARAMETER session
        The Check Point session ID for authentication.

    .PARAMETER filter
        The log filter expression for a new query.

    .PARAMETER timeframe
        A timeFrame object defining the time range for the query.

    .PARAMETER maxlogsperrequest
        Maximum number of logs per request (1-100). Defaults to 100.

    .PARAMETER queryId
        The query ID to continue fetching results from an existing query.

    .PARAMETER ignoreSSLError
        When specified, disables SSL certificate validation.

    .OUTPUTS
        PSObject. The log query results from the API.

    .EXAMPLE
        Get-CheckPointLogs -server "mgmt" -port 443 -session $sid -filter "action:Drop" -timeframe ([timeFrame]::new("last-hour"))

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "NewQuery")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "QueryId")]
        [string]$server,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "NewQuery")]
        [Parameter(Mandatory, Position = 1, ParameterSetName = "QueryId")]
        [ValidateRange(1,65535)]
        [int]$port,
        [Parameter(Mandatory, Position = 2, ParameterSetName = "NewQuery")]
        [Parameter(Mandatory, Position = 2, ParameterSetName = "QueryId")]
        [string]$session,
        [Parameter(Mandatory, Position = 3, ParameterSetName = "NewQuery")]
        [string]$filter,
        [Parameter(Mandatory, Position = 4, ParameterSetName = "NewQuery")]
        [timeFrame]$timeframe,
        [Parameter(Position = 5, ParameterSetName = "NewQuery")]
        [ValidateRange(1,100)]
        [int]$maxlogsperrequest = 100,
        [Parameter(Mandatory, Position = 2, ParameterSetName = "QueryId")]
        [string]$queryId,
        [switch]$ignoreSSLError
    )
    $url = "https://${server}:$port/web_api/show-logs"
    $body = switch ($PSCmdlet.ParameterSetName) {
        "NewQuery" {
            [hashtable]$newQyery = @{
                filter = $filter
                "time-frame" = $timeframe.value
                "max-logs-per-request" = $maxlogsperrequest
            }
            if ($timeframe.isCustomValue()) {
                $newQuery.Add("custom-start", $timeframe.getStartString())
                $newQuery.Add("custom-end", $timeframe.getEndString())
            }
            @{
                "new-query" = $newQyery
            } | ConvertTo-Json
        }
        "QueryId" {
            @{
                "query-id" = $queryId
            } | ConvertTo-Json
        }
    }
    return (Invoke-CheckPointAPI -url $url -body $body -session $session -ignoreSSLError:($ignoreSSLError.IsPresent))
}