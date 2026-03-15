# function Connect-ManagementAPI {
#     <#
#     .SYNOPSIS
#         Connects to the Check Point Management API and creates a session object.

#     .DESCRIPTION
#         Authenticates to the Check Point Management server via the Web API login endpoint.
#         Returns a connection object with CallAPI(), CallAPIWithDetails(), CallAllPagesAPI(),
#         and Reconnect() methods. Also populates gateway and interoperable device caches,
#         and registers the management in global hashtables for cross-session lookup.

#     .PARAMETER Address
#         The IP address or hostname of the Check Point management server.

#     .PARAMETER Port
#         The port number for the Web API (typically 443).

#     .PARAMETER Username
#         The username for authentication (used with Password parameter set).

#     .PARAMETER Password
#         The password as a SecureString (used with Username parameter set).

#     .PARAMETER Credential
#         A PSCredential object for authentication (alternative to Username/Password).

#     .PARAMETER ignoreSSLError
#         When specified, disables SSL certificate validation.

#     .PARAMETER GlobalVar
#         When specified, stores the connection object in $Global:MgmtAPI.

#     .OUTPUTS
#         PSObject. A connection object with API calling methods and cached gateway information.

#     .EXAMPLE
#         $mgmt = Connect-ManagementAPI -Address "192.168.1.1" -Port 443 -Username "admin" -Password $secPwd -ignoreSSLError

#     .EXAMPLE
#         Connect-ManagementAPI -Address "mgmt.example.com" -Port 443 -Credential $cred -GlobalVar

#     .NOTES
#         Author  : Loïc Ade
#         Version : 1.0.0
#     #>
#     Param(
#         [Parameter(Position = 0)]
#         [string]$Address,
#         [Parameter(Position = 1)]
#         [int]$Port,
#         [Parameter(Position = 2, ParameterSetName = "userpasswd")]
#         [string]$Username,
#         [Parameter(Position = 3, ParameterSetName = "userpasswd")]
#         [securestring]$Password,
#         [Parameter(Position = 2, ParameterSetName = "credential")]
#         [pscredential]$Credential,
#         [switch]$ignoreSSLError,
#         [switch]$GlobalVar
#     )
#     $sUsername, $oPassword = if ($PSCmdlet.ParameterSetName -eq "credential") {
#         $Credential.UserName, $Credential.Password
#     } else {
#         $Username, $Password
#     }
#     $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($oPassword)
#     $sPlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

#     $body = @{
#         user = $sUsername
#         password = $sPlainTextPassword
#     } | ConvertTo-Json
#     $url = "https://$Address`:$Port/web_api/login"
#     $hHeaders = @{
#         "Content-Type" = "application/json"
#     }
#     if ($IgnoreSSLError) {
#         Invoke-IgnoreSSL
#     }

#     $Login = Invoke-RestMethod -Uri $url -Body $body -Method 'POST' -Headers $hHeaders
#     $oResult = [pscustomobject]@{
#         Address = $Address
#         Port = $Port
#         Username = $sUsername
#         Password = $oPassword
#         BaseURL = "https://$Address`:$Port/web_api/"
#         Login = $Login
#         IgnoreSSLError = $ignoreSSLError.IsPresent
#         LatestTask = ""
#         Object = $null
#         Gateways = @()
#         GatewaysHashtable = @{}
#         InteroperableDevices = @()
#         WriteDetailedErrors = $false
#         Dictionary = $null
#     }

#     $oResult | Add-Member -MemberType ScriptMethod -Name "Reconnect" -Value {
#         if ($this.IgnoreSSLError) {
#             Invoke-IgnoreSSL
#         }
#         $url = $this.BaseURL + "login"
#         $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password)
#         $sPlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
#         $body = @{
#             user = $this.Username
#             password = $sPlainTextPassword
#         } | ConvertTo-Json
#         $hHeaders = @{
#             "Content-Type" = "application/json"
#         }
#         $Login = Invoke-RestMethod -Uri $url -Body $body -Method 'POST' -Headers $hHeaders
#         $this.Login = $Login
#     }
    
#     $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPIWithDetails" -Value {
#         Param([string]$url,[hashtable]$arguments = @{})
#         if ($this.IgnoreSSLError) {
#             Invoke-IgnoreSSL
#         }
#         $headers = @{
#             "Content-Type" = "application/json"
#             "X-chkp-sid" = $this.Login.sid
#         }
#         $sBody = $arguments | ConvertTo-Json
#         $sUrl = if ($url -like "*://*") {
#             $url
#         } else {
#             $this.BaseURL + $url
#         }
#         $oAPICall = try {
#             Invoke-WebRequest -Uri $sUrl -Body $sBody -Method 'POST' -Headers $headers -UseBasicParsing
#         } catch [System.Net.WebException] {
#             $errorResponse = $_.Exception.Response
#             if ($errorResponse.StatusCode.Value__ -eq 401) {
#                 $this.Reconnect()
#                 $headers = @{
#                     "Content-Type" = "application/json"
#                     "X-chkp-sid" = $this.Login.sid
#                 }
#                 Invoke-WebRequest -Uri $sUrl -Body $sBody -Method 'POST' -Headers $headers -UseBasicParsing
#             } else {
#                 $errorResponse
#             }
#         }

#         $oResult = [pscustomobject]@{
#             http = $oAPICall
#             json = $oAPICall.Content | ConvertFrom-Json
#             status = if ($oAPICall.StatusCode -eq 200) { "OK" } else { "Error" }
#             url = $sUrl
#             body = $body
#         }
#         $oResult | Add-Member MemberSet PSStandardMembers $PSStandardMembers 
#         return $oResult
#     }

#     $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPI" -Value {
#         Param([string]$url,[object]$arguments = @{})
#         $result = $this.CallAPIWithDetails($url, $arguments)
#         if ($result.status -eq "OK") {
#             return $result.json
#         } else {
#             if ($this.WriteDetailedErrors) {
#                 Write-Host "URL: $url" -ForegroundColor Red
#                 $sArguments = $arguments | ConvertTo-Json
#                 Write-Host "Arguments:" -ForegroundColor Red
#                 Write-Host "$sArguments" -ForegroundColor Red
#             }
#             throw [System.InvalidOperationException] "Error happened when calling api $url"
#         }
#     }

#     $oResult | Add-Member -MemberType ScriptMethod -Name "CallAllPagesAPI" -Value {
#         Param([string]$url,[hashtable]$arguments, [string[]]$AllObjectsProperty = @("objects"), [string]$WriteProgressMessage = "")
#         if ($WriteProgressMessage -ne "") {
#             Write-Progress -Activity $WriteProgressMessage -Status "Page 1"
#         }
#         $apiResult = $this.CallAPI($url, $arguments)
#         $oResult = $apiResult
#         $hBody = Copy-Hashtable -InputObject $arguments

#         if ($arguments.offset -eq 0) {
#             $iLastPage = [Math]::Ceiling($apiResult.total / [int]$arguments["limit"])
#             for ($i = 1; $i -lt $iLastPage; $i++) {
#                 if ($WriteProgressMessage -ne "") {
#                     Write-Progress -Activity $WriteProgressMessage -PercentComplete (($i / $iLastPage) * 100) -Status "Page $($i + 1) / $($iLastPage + 1)"
#                 }
#                 $hBody["offset"] = $i * $arguments["limit"]
#                 $apiResult = $this.CallAPI($url, $hBody)
#                 foreach($property in $AllObjectsProperty) {
#                     $oResult.$property += $apiResult.$property
#                 }
#             }
#             $oResult.to = $oResult.total
#             if ($WriteProgressMessage -ne "") {
#                 Write-Progress -Activity $WriteProgressMessage -Completed
#             }
#         } else {
#             throw "Can't get all items if offset is greater than 0"
#         }

#         foreach($property in $AllObjectsProperty) {
#             foreach ($oObject in $oResult.$property) {
#                 $oObject | Add-Member -NotePropertyName "Management" -NotePropertyValue $this
#             }
#         }

#         return $oResult
#     }

#     $oResult.Object = Get-CheckPointHost -ManagementInfo $oResult

#     # add management to global hashtable, for all interesting properties
#     $oManagementObject = $oResult.Object
#     if ($null -eq $Global:CPManagementHashtable) {
#         $Global:CPManagementHashtable = @{}
#     }
#     $Global:CPManagementHashtable[$oManagementObject.name] = $oResult
#     $Global:CPManagementHashtable[$oManagementObject.uid] = $oResult
#     if ($oManagementObject."ipv4-address") {
#         $Global:CPManagementHashtable[$oManagementObject."ipv4-address"] = $oResult
#     }
#     if ($oManagementObject."ipv6-address") {
#         $Global:CPManagementHashtable[$oManagementObject."ipv6-address"] = $oResult
#     }
#     if ($oManagementObject."nat-settings"."ipv4-address") {
#         $Global:CPManagementHashtable[$oManagementObject."nat-settings"."ipv4-address"] = $oResult
#     }
#     if ($oManagementObject."nat-settings"."ipv6-address") {
#         $Global:CPManagementHashtable[$oManagementObject."nat-settings"."ipv6-address"] = $oResult
#     }

#     # add management to global list
#     if ($null -eq $Global:CPManagement) {
#         $Global:CPManagement = @()
#     }
#     $Global:CPManagement += $oResult

#     # add gateways to management object (list)
#     $oResult.Gateways = (Get-Gateway -ManagementInfo $oResult -details-level full -All).objects
#     # add gateways to management object (hashtable)
#     foreach ($oGateway in $oResult.Gateways) {
#         $oResult.GatewaysHashtable[$oGateway.name] = $oGateway
#         $oResult.GatewaysHashtable[$oGateway.uid] = $oGateway
#         if ($oGateway."ipv4-address") { $oResult.GatewaysHashtable[$oGateway."ipv4-address"] = $oGateway }
#         if ($oGateway."ipv6-address") { $oResult.GatewaysHashtable[$oGateway."ipv6-address"] = $oGateway }
#     }
#     $oResult.InteroperableDevices = (Get-InteroperableDevice  -ManagementInfo $oResult -details-level full -All).objects
#     if ($null -eq $Global:CPInteroperableDevices) {
#         $Global:CPInteroperableDevices = @()
#     }
#     foreach ($oDevice in $oResult.InteroperableDevices) {
#         $Global:CPInteroperableDevices += $oDevice
#     }

#     if ($GlobalVar.IsPresent) {
#         $Global:MgmtAPI = $oResult
#     } else {
#         return $oResult
#     }
# }


function Connect-ManagementAPI {
    <#
    .SYNOPSIS
        Connects to one or more Check Point Management API servers and creates session objects.

    .DESCRIPTION
        Authenticates to one or more Check Point Management servers via the Web API login endpoint.
        Returns one connection object per server with CallAPI(), CallAPIWithDetails(), CallAllPagesAPI(),
        and Reconnect() methods. Also populates gateway and interoperable device caches,
        and registers each management in global hashtables for cross-session lookup.

        The port can be embedded in the address using "host:port" notation for IPv4/hostnames,
        or "[ipv6]:port" notation for IPv6 addresses. The -Port parameter acts as the default
        port when no port is specified in the address.

        This function has two behavioural modes depending on how it is invoked:

        CONNECT mode (called as Connect-ManagementAPI):
            All global tracking variables are reset before connecting:
            $Global:CPManagement, $Global:CPManagementHashtable,
            $Global:CPInteroperableDevices and $Global:MgmtAPI are cleared.
            Use -GlobalVar to populate $Global:MgmtAPI after connecting.
            Results are returned to the pipeline when -GlobalVar is not specified.

        ADD mode (called as Add-ManagementAPI, alias of this function):
            Global variables are never reset; each connection is appended to
            existing globals. $Global:MgmtAPI is always updated regardless of -GlobalVar.
            Results are not returned to the pipeline.

    .PARAMETER Address
        One or more IP addresses or hostnames of Check Point management servers.
        The port can be embedded using "host:port" (e.g. "192.168.1.1:8443") or
        "[ipv6]:port" (e.g. "[2001:db8::1]:443") notation.

    .PARAMETER Port
        The default port number for the Web API (default: 443).
        Used when no port is embedded in the address string.

    .PARAMETER Username
        The username for authentication (used with Password parameter set).

    .PARAMETER Password
        The password as a SecureString (used with Username parameter set).

    .PARAMETER Credential
        A PSCredential object for authentication (alternative to Username/Password).

    .PARAMETER ignoreSSLError
        When specified, disables SSL certificate validation.

    .PARAMETER GlobalVar
        Connect mode: populates $Global:MgmtAPI and suppresses pipeline output.
        Add mode: ignored ($Global:MgmtAPI is always updated in Add mode).

    .OUTPUTS
        PSObject. One connection object per address (Connect mode without -GlobalVar only).

    .EXAMPLE
        $mgmt = Connect-ManagementAPI -Address "192.168.1.1" -Port 443 -Username "admin" -Password $secPwd -ignoreSSLError

    .EXAMPLE
        Connect-ManagementAPI -Address "mgmt.example.com:443" -Credential $cred -GlobalVar

    .EXAMPLE
        $connections = Connect-ManagementAPI -Address "192.168.1.1:443","192.168.1.2:8443","mgmt3.example.com" -Port 443 -Credential $cred

    .EXAMPLE
        # Add-ManagementAPI is an alias: resets nothing, always appends to globals
        Add-ManagementAPI -Address "mgmt3.lab:443" -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0
    #>
    Param(
        [Parameter(Position = 0)]
        [string[]]$Address,
        [Parameter(Position = 1)]
        [int]$Port = 4434,
        [Parameter(Position = 2, ParameterSetName = "userpasswd")]
        [string]$Username,
        [Parameter(Position = 3, ParameterSetName = "userpasswd")]
        [securestring]$Password,
        [Parameter(Position = 2, ParameterSetName = "credential")]
        [pscredential]$Credential,
        [switch]$ignoreSSLError,
        [switch]$GlobalVar
    )
    $sUsername, $oPassword = if ($PSCmdlet.ParameterSetName -eq "credential") {
        $Credential.UserName, $Credential.Password
    } else {
        $Username, $Password
    }
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($oPassword)
    $sPlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    $body = @{
        user = $sUsername
        password = $sPlainTextPassword
    } | ConvertTo-Json
    $hHeaders = @{
        "Content-Type" = "application/json"
    }
    if ($IgnoreSSLError) {
        Invoke-IgnoreSSL
    }

    # Detect invocation mode via alias name
    $bCalledAsAdd = $MyInvocation.InvocationName -ne 'Connect-ManagementAPI'
    if (-not $bCalledAsAdd) {
        # Connect mode: reset all global tracking variables for a fresh context
        $Global:CPManagement          = @()
        $Global:CPManagementHashtable = @{}
        $Global:CPInteroperableDevices = @()
        $Global:MgmtAPI               = $null
    }

    foreach ($sAddr in $Address) {
        # Parse embedded port from address string
        if ($sAddr -match '^\[(.+)\]:(\d+)$') {
            # IPv6 with port: [2001:db8::1]:443
            $sHost = $Matches[1]
            $iPort = [int]$Matches[2]
        } elseif ($sAddr -match '^([^:\[]+):(\d+)$') {
            # IPv4 or hostname with port: 192.168.1.1:443 or mgmt.example.com:8443
            $sHost = $Matches[1]
            $iPort = [int]$Matches[2]
        } else {
            # No port in address: use -Port default
            $sHost = $sAddr
            $iPort = $Port
        }

        $url = "https://$sHost`:$iPort/web_api/login"
        $Login = Invoke-RestMethod -Uri $url -Body $body -Method 'POST' -Headers $hHeaders
        $oResult = [pscustomobject]@{
            Address = $sHost
            Port = $iPort
            Username = $sUsername
            Password = $oPassword
            BaseURL = "https://$sHost`:$iPort/web_api/"
            Login = $Login
            IgnoreSSLError = $ignoreSSLError.IsPresent
            LatestTask = ""
            Object = $null
            Gateways = @()
            GatewaysHashtable = @{}
            InteroperableDevices = @()
            WriteDetailedErrors = $false
            Dictionary = $null
        }

        $oResult | Add-Member -MemberType ScriptMethod -Name "Reconnect" -Value {
            if ($this.IgnoreSSLError) {
                Invoke-IgnoreSSL
            }
            $url = $this.BaseURL + "login"
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password)
            $sPlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            $body = @{
                user = $this.Username
                password = $sPlainTextPassword
            } | ConvertTo-Json
            $hHeaders = @{
                "Content-Type" = "application/json"
            }
            $Login = Invoke-RestMethod -Uri $url -Body $body -Method 'POST' -Headers $hHeaders
            $this.Login = $Login
        }
        
        $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPIWithDetails" -Value {
            Param([string]$url,[hashtable]$arguments = @{})
            if ($this.IgnoreSSLError) {
                Invoke-IgnoreSSL
            }
            $headers = @{
                "Content-Type" = "application/json"
                "X-chkp-sid" = $this.Login.sid
            }
            $sBody = $arguments | ConvertTo-Json
            $sUrl = if ($url -like "*://*") {
                $url
            } else {
                $this.BaseURL + $url
            }
            $oAPICall = try {
                Invoke-WebRequest -Uri $sUrl -Body $sBody -Method 'POST' -Headers $headers -UseBasicParsing
            } catch [System.Net.WebException] {
                $errorResponse = $_.Exception.Response
                if ($errorResponse.StatusCode.Value__ -eq 401) {
                    $this.Reconnect()
                    $headers = @{
                        "Content-Type" = "application/json"
                        "X-chkp-sid" = $this.Login.sid
                    }
                    Invoke-WebRequest -Uri $sUrl -Body $sBody -Method 'POST' -Headers $headers -UseBasicParsing
                } else {
                    $errorResponse
                }
            }

            $oResult = [pscustomobject]@{
                http = $oAPICall
                json = $oAPICall.Content | ConvertFrom-Json
                status = if ($oAPICall.StatusCode -eq 200) { "OK" } else { "Error" }
                url = $sUrl
                body = $body
            }
            $oResult | Add-Member MemberSet PSStandardMembers $PSStandardMembers 
            return $oResult
        }

        $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPI" -Value {
            Param([string]$url,[object]$arguments = @{})
            $result = $this.CallAPIWithDetails($url, $arguments)
            if ($result.status -eq "OK") {
                return $result.json
            } else {
                if ($this.WriteDetailedErrors) {
                    Write-Host "URL: $url" -ForegroundColor Red
                    $sArguments = $arguments | ConvertTo-Json
                    Write-Host "Arguments:" -ForegroundColor Red
                    Write-Host "$sArguments" -ForegroundColor Red
                }
                throw [System.InvalidOperationException] "Error happened when calling api $url"
            }
        }

        $oResult | Add-Member -MemberType ScriptMethod -Name "CallAllPagesAPI" -Value {
            Param([string]$url,[hashtable]$arguments, [string[]]$AllObjectsProperty = @("objects"), [string]$WriteProgressMessage = "")
            if ($WriteProgressMessage -ne "") {
                Write-Progress -Activity $WriteProgressMessage -Status "Page 1"
            }
            $apiResult = $this.CallAPI($url, $arguments)
            $oResult = $apiResult
            $hBody = Copy-Hashtable -InputObject $arguments

            if ($arguments.offset -eq 0) {
                $iLastPage = [Math]::Ceiling($apiResult.total / [int]$arguments["limit"])
                for ($i = 1; $i -lt $iLastPage; $i++) {
                    if ($WriteProgressMessage -ne "") {
                        Write-Progress -Activity $WriteProgressMessage -PercentComplete (($i / $iLastPage) * 100) -Status "Page $($i + 1) / $($iLastPage + 1)"
                    }
                    $hBody["offset"] = $i * $arguments["limit"]
                    $apiResult = $this.CallAPI($url, $hBody)
                    foreach($property in $AllObjectsProperty) {
                        $oResult.$property += $apiResult.$property
                    }
                }
                $oResult.to = $oResult.total
                if ($WriteProgressMessage -ne "") {
                    Write-Progress -Activity $WriteProgressMessage -Completed
                }
            } else {
                throw "Can't get all items if offset is greater than 0"
            }

            foreach($property in $AllObjectsProperty) {
                foreach ($oObject in $oResult.$property) {
                    $oObject | Add-Member -NotePropertyName "Management" -NotePropertyValue $this
                }
            }

            return $oResult
        }

        $oResult.Object = Get-CheckPointHost -ManagementInfo $oResult

        # add management to global hashtable, for all interesting properties
        $oManagementObject = $oResult.Object
        if ($null -eq $Global:CPManagementHashtable) {
            $Global:CPManagementHashtable = @{}
        }
        $Global:CPManagementHashtable[$oManagementObject.name] = $oResult
        $Global:CPManagementHashtable[$oManagementObject.uid] = $oResult
        if ($oManagementObject."ipv4-address") {
            $Global:CPManagementHashtable[$oManagementObject."ipv4-address"] = $oResult
        }
        if ($oManagementObject."ipv6-address") {
            $Global:CPManagementHashtable[$oManagementObject."ipv6-address"] = $oResult
        }
        if ($oManagementObject."nat-settings"."ipv4-address") {
            $Global:CPManagementHashtable[$oManagementObject."nat-settings"."ipv4-address"] = $oResult
        }
        if ($oManagementObject."nat-settings"."ipv6-address") {
            $Global:CPManagementHashtable[$oManagementObject."nat-settings"."ipv6-address"] = $oResult
        }

        # add management to global list
        if ($null -eq $Global:CPManagement) {
            $Global:CPManagement = @()
        }
        $Global:CPManagement += $oResult

        # add gateways to management object (list)
        $oResult.Gateways = (Get-Gateway -ManagementInfo $oResult -details-level full -All).objects
        # add gateways to management object (hashtable)
        foreach ($oGateway in $oResult.Gateways) {
            $oResult.GatewaysHashtable[$oGateway.name] = $oGateway
            $oResult.GatewaysHashtable[$oGateway.uid] = $oGateway
            if ($oGateway."ipv4-address") { $oResult.GatewaysHashtable[$oGateway."ipv4-address"] = $oGateway }
            if ($oGateway."ipv6-address") { $oResult.GatewaysHashtable[$oGateway."ipv6-address"] = $oGateway }
        }
        $oResult.InteroperableDevices = (Get-InteroperableDevice  -ManagementInfo $oResult -details-level full -All).objects
        if ($null -eq $Global:CPInteroperableDevices) {
            $Global:CPInteroperableDevices = @()
        }
        foreach ($oDevice in $oResult.InteroperableDevices) {
            $Global:CPInteroperableDevices += $oDevice
        }

        if ($bCalledAsAdd) {
            # Add mode: accumulate in MgmtAPI only if already populated; never output to pipeline
            if ($null -ne $Global:MgmtAPI) {
                if ($Global:MgmtAPI -isnot [System.Array]) {
                    $Global:MgmtAPI = @($Global:MgmtAPI)
                }
                $Global:MgmtAPI += $oResult
            }
        } elseif ($GlobalVar.IsPresent) {
            # Connect mode with -GlobalVar: populate MgmtAPI, no pipeline output
            if ($Address.Count -gt 1) {
                if ($null -eq $Global:MgmtAPI) { $Global:MgmtAPI = @() }
                $Global:MgmtAPI += $oResult
            } else {
                $Global:MgmtAPI = $oResult
            }
        } else {
            # Connect mode without -GlobalVar: return to pipeline
            $oResult
        }
    }
}

Set-Alias Add-ManagementAPI Connect-ManagementAPI