function Invoke-CheckPointAPI {
    <#
    .SYNOPSIS
        Sends a raw POST request to the Check Point Management API.

    .DESCRIPTION
        Low-level function that sends an HTTP POST request to a Check Point API endpoint
        with optional session token authentication and SSL error bypassing.

    .PARAMETER url
        The full URL of the API endpoint.

    .PARAMETER body
        The JSON request body as a string.

    .PARAMETER session
        The Check Point session ID (X-chkp-sid header value).

    .PARAMETER ignoreSSLError
        When specified, disables SSL certificate validation.

    .OUTPUTS
        Microsoft.PowerShell.Commands.HtmlWebResponseObject. The raw HTTP response.

    .EXAMPLE
        Invoke-CheckPointAPI -url "https://mgmt:443/web_api/show-hosts" -body '{"limit":10}' -session $sid

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$url,
        [string]$body,
        [string]$session,
        [switch]$ignoreSSLError
    )
    if ($ignoreSSLError.IsPresent) {
        Invoke-IgnoreSSL
    }
    $headers = @{
        "Content-Type" = "application/json"
    }
    if ($session) {
        $headers.Add("X-chkp-sid", $session)
    }
    return (Invoke-WebRequest -Uri $url -Body $body -Method 'POST' -Headers $headers)
}