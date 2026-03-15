# PSSomeCheckPointNPMThings

A PowerShell module wrapping the Check Point Management API (on-premise): authentication, network objects CRUD, firewall rules, NAT rulebases, services, policy installation, log queries, session management, and remote command execution on gateways via cprid_util and dbedit.

## Features

### Connect
Authenticate and manage connections to Check Point Management servers.

| Function | Description |
|---|---|
| `Connect-ManagementAPI` | Authenticates to the Check Point Management API. Returns a connection object with `CallAPI()`, `CallAllPagesAPI()`, and `Reconnect()` methods. Supports `-GlobalVar` to store in `$Global:MgmtAPI`. |
| `Connect-ManagementCUI` | Interactive CLI connection with credential prompts via `Read-CLIDialogCredential`. Connects to one or more management servers and registers argument completers. |

### Access Control

#### Access Layers & Rules

| Function | Description |
|---|---|
| `Get-AccessLayer` | Retrieves access layers by name, UID, or lists all with pagination. |
| `Get-AccessRulebase` | Retrieves the access rulebase for a policy package with pagination, filtering, hit counts, and optional flattening. |
| `Get-AccessRule` | Retrieves a single access rule. *(stub)* |

#### NAT Rules

| Function | Description |
|---|---|
| `Get-NatRulebase` | Retrieves the NAT rulebase for a policy package. Supports caching, section flattening, UID expansion to full objects, and group member dereferencing. |
| `Get-NatRuleType` | Classifies a NAT rule into one of four types: NoNat, InternalToPublic_Internal, InternalToInternal_Internal, or InternalToInternal_Public. |
| `Test-IsNoNatRule` | Tests if a NAT rule is a "No NAT" rule (all translated fields are "Original"). |
| `Test-IsInternalToInternalInternalNatRule` | Tests if a NAT rule maps internal source to internal destination with internal translated destination. |
| `Test-IsInternalToInternalPublicNatRule` | Tests if a NAT rule maps internal source to internal destination with public translated destination. |
| `Test-IsInternalToPublicInternalNATRule` | Tests if a NAT rule is a static rule mapping internal source to public destination with internal translated destination. |

### Network Objects

Full CRUD operations for Check Point network objects.

#### Hosts

| Function | Description |
|---|---|
| `Get-HostObject` | Gets host objects by UID/name or lists all with pagination. |
| `New-HostObject` | Creates a new host object with IPv4 or IPv6 address. |
| `Update-HostObject` | Updates an existing host object (name, IP, comments). |
| `Remove-HostObject` | Deletes a host object. |

#### Networks (Subnets)

| Function | Description |
|---|---|
| `Get-NetworkObject` | Gets network objects by UID/name or lists all. |
| `New-NetworkObject` | Creates a new network object with subnet and mask. |

#### Address Ranges

| Function | Description |
|---|---|
| `Get-AddressRange` | Gets address range objects by UID/name or lists all. |
| `New-AddressRange` | Creates a new address range with IPv4/IPv6 first-last pairs. |
| `Update-AddressRange` | Updates an existing address range. |
| `Remove-AddressRange` | Deletes an address range. |

#### Groups

| Function | Description |
|---|---|
| `Get-NetworkGroup` | Gets network groups by UID/name or lists all. Supports recursive member expansion. |
| `Get-RecursiveGroupMembers` | Recursively resolves all members of a group, expanding nested groups to leaf objects. |
| `New-NetworkGroup` | Creates a new network group with members. |
| `Update-NetworkGroup` | Updates a network group (set, add, or remove members). |
| `Update-NetworkGroupFromJson` | Updates a network group from a JSON data source with XPath filtering. Auto-creates missing objects. |
| `Remove-NetworkGroup` | Deletes a network group. |
| `Test-IPInGroup` | Tests whether an IP address belongs to a network group. |

<details>
<summary>Other Network Object Types</summary>

| Function | Description |
|---|---|
| `Get-Gateway` | Retrieves gateways/servers by UID, name, IPv4, IPv6, or auto-detection. Registers found gateways in global caches. |
| `Get-SimpleGateway` | Gets simple gateway objects by UID/name or lists all. |
| `Get-SimpleCluster` | Gets simple cluster objects by UID/name or lists all. |
| `Get-GatewayPlatform` | Gets platform information for a gateway. |
| `Get-GatewayPublicInterface` | Determines public interfaces and applicable NAT rules for a gateway. |
| `Test-GatewayHasPublicInterface` | Tests whether a gateway has at least one public (non-RFC1918) interface. |
| `Get-CheckPointHost` | Gets Check Point host objects. Supports auto-detection of the management server's own host. |
| `Get-DNSDomain` | Gets DNS domain objects by UID/name or lists all. |
| `New-DNSDomain` | Creates a new DNS domain object. |
| `Get-InteroperableDevice` | Gets interoperable device objects (VPN peers) by UID/name or lists all. |
| `Get-Tag` | Gets tag objects by UID/name or lists all. |
| `New-CPObject` | Smart object creation: auto-detects the value type (IP, CIDR, range, DNS name) and creates the appropriate object. |
| `Test-CPObject` | Tests if a Check Point object exists by name or value. |

</details>

### Services

CRUD operations for TCP, UDP services and service groups.

| Function | Description |
|---|---|
| `Get-TCPService` | Gets TCP service objects by UID/name or lists all. |
| `New-TCPService` | Creates a new TCP service with port or port range. |
| `Update-TCPService` | Updates an existing TCP service. |
| `Remove-TCPService` | Deletes a TCP service. |
| `Get-UDPService` | Gets UDP service objects by UID/name or lists all. |
| `New-UDPService` | Creates a new UDP service with port or port range. |
| `Update-UDPService` | Updates an existing UDP service. |
| `Remove-UDPService` | Deletes a UDP service. |
| `Get-ServiceGroup` | Gets service groups by UID/name or lists all. Supports recursive member expansion. |
| `New-ServiceGroup` | Creates a new service group. |
| `Update-ServiceGroup` | Updates a service group (set, add, or remove members). |
| `Remove-ServiceGroup` | Deletes a service group. |

### Policy

| Function | Description |
|---|---|
| `Get-PolicyPackage` | Gets policy packages by UID/name or lists all. |
| `Install-Policy` | Installs a policy package to target gateways. Supports waiting for task completion. |

### Session

| Function | Description |
|---|---|
| `Invoke-SessionPublish` | Publishes pending changes. Optionally waits for completion with configurable timeout. |
| `Invoke-SessionDiscard` | Discards uncommitted changes in the current session. |
| `Invoke-SessionLogout` | Logs out from the Management API session. |

### Logs

| Function | Description |
|---|---|
| `Get-CheckPointLogs` | Queries Check Point logs via the show-logs API with filter and time frame support. Supports continuing existing queries by ID. |
| `Get-FilteredCheckPointLogs` | Retrieves all log pages and applies a custom filter scriptblock to each entry. |

### Generic / Misc

| Function | Description |
|---|---|
| `Invoke-CheckPointAPI` | Low-level REST API call function with session token and SSL error support. |
| `Get-GenericObjectCollection` | Generic paginated API query for any `show-*` command. Handles single-page or all-pages retrieval. |
| `Get-FlattenedRulebase` | Flattens a hierarchical rulebase (sections with sub-rules) into a flat array. |
| `Resolve-CPObjectIdentifier` | Auto-detects whether an identifier is a UID or a name. Returns `@{uid=...}` or `@{name=...}`. |
| `Convert-CPObjectToString` | Converts a Check Point object to its string representation based on type (network, host, range, gateway, etc.). |
| `Expand-Group` | Recursively expands group members from UIDs to full objects (in-place). |

<details>
<summary>Object Queries & Caches</summary>

| Function | Description |
|---|---|
| `Get-Object` | Retrieves a single object by UID or name with optional group membership info. |
| `Get-Objects` | Retrieves objects with filtering, pagination, and type filtering via `show-objects`. |
| `Get-ObjectsDictionnary` | Creates or retrieves a cached objects dictionary with `Fill()`, `Get(uid)`, and `AppendDictionary()` methods. |
| `Get-ObjectTagValue` | Extracts a tag value from an object (tags in "TagName:Value" format). |
| `Where-Used` | Finds where an object is used. *(stub)* |
| `Get-ManagementFromCache` | Resolves a management identifier to a connection object from global caches. |
| `Get-GetwayAndManagementFromCache` | Resolves a firewall identifier to gateway and management objects from caches. |

</details>

<details>
<summary>Tasks</summary>

| Function | Description |
|---|---|
| `Get-Task` | Retrieves task status from the Management API. |
| `Wait-Task` | Polls a task until completion or timeout with optional progress bar. |

</details>

### Remote Execution (cprid_util)

Execute commands on remote Check Point gateways via the cprid_util infrastructure.

| Function | Description |
|---|---|
| `Invoke-Cpridutil` | Core cprid_util wrapper. Runs commands on remote firewalls via `rexec`. Supports "long output" mode for large results. |
| `Invoke-CpridutilBash` | Runs a bash command on a remote firewall. Auto-parses output as JSON, regex match, or plain string. |
| `Invoke-CpridutilClish` | Runs a clish command on a remote firewall with the same parsing logic. |
| `Invoke-RunScript` | Executes a script on a target via the `run-script` API. Waits for task completion and decodes base64 response. |

<details>
<summary>Gateway Information Functions</summary>

| Function | Description |
|---|---|
| `Get-CPGaiaConfiguration` | Retrieves the full Gaia `show configuration` output. |
| `Get-CPRoutingTable` | Retrieves and parses the routing table into structured objects (Destination, Protocol, NextHop, Interface, Cost). |
| `Get-CPJumboHotfix` | Gets the installed Jumbo Hotfix "Take" number. |
| `Get-CPSystemVendor` | Gets the hardware system vendor string. |
| `Get-CPInternetConnections` | Gets WAN interfaces with IP, mask, and default gateway. Handles Gaia Embedded and standard Gaia. |
| `Invoke-FwVer` | Runs `fw ver` and parses model, version, and build. |
| `Invoke-CPInfo` | Runs `cpinfo` with optional arguments. |
| `Invoke-ShowAssetAll` | Runs `show asset all` and returns a hashtable. |
| `Invoke-ShowDiag` | Runs `show diag` and parses diagnostics output. |
| `Invoke-FwUnloadlocal` | Runs `fw unloadlocal` (unloads local firewall policy). |
| `Invoke-VPNTu` | Runs VPN tunnel utility commands (list IKE SAs, IPSec SAs, tunnels). |
| `Export-CPFirewallConfig` | Exports Gaia configuration for firewalls to text files. |

</details>

<details>
<summary>Cloud Metadata Functions</summary>

| Function | Description |
|---|---|
| `Get-CPAWSMetadata` | Retrieves AWS EC2 instance metadata via IMDSv2. |
| `Get-CPAWSMetadataToken` | Obtains an AWS EC2 IMDSv2 metadata token. |
| `Get-CPAWSMac` | Retrieves the MAC address from AWS EC2 instance metadata. |
| `Get-CPAzureMetadata` | Retrieves Azure instance metadata. |

</details>

### Database Edit (dbedit)

| Function | Description |
|---|---|
| `Invoke-Dbedit` | Executes dbedit commands on the management server via `run-script`. Handles multi-line commands and parses output. |
| `Get-DBEditObject` | Retrieves a database object in XML format via `dbedit printxml`. |

### Users

| Function | Description |
|---|---|
| `Get-UserGroup` | Gets user groups by UID/name or lists all. |

### Class

| Class | Description |
|---|---|
| `timeFrame` | PowerShell class for log query time frames. Supports predefined values ("last-7-days", "last-hour", "today") and custom date ranges. |

## Requirements

- **PowerShell** 5.1 or later
- **Check Point Management Server** on-premise (R80.x / R81.x) with the Management API enabled
- Network access to the management server API port (default: 443)
- Valid administrator credentials with API access
- For cprid_util functions: SIC trust established between management and gateways

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeCheckPointNPMThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeCheckPointNPMThings" -Recurse

# Or import directly
Import-Module ".\PSSomeCheckPointNPMThings\PSSomeCheckPointNPMThings.psd1"
```

## Quick Start

### Connect to the Management API

```powershell
# Authenticate with credentials
$secPassword = Read-Host -AsSecureString -Prompt "Password"
Connect-ManagementAPI -Address "mgmt.example.com" -Username "admin" -Password $secPassword `
                      -ignoreSSLError -GlobalVar

# Or use interactive CLI connection
Connect-ManagementCUI -ManagementAddress "mgmt.example.com"
```

### Manage network objects

```powershell
# Create a host object
New-HostObject -name "WebServer01" -ipv4-address "10.0.1.10" -comments "Production web server"

# Create a network object
New-NetworkObject -name "ServerSubnet" -subnet4 "10.0.1.0" -mask-length4 24

# Smart creation (auto-detects type from value)
New-CPObject -Name "MyHost" -Value "10.0.1.10"         # Creates a host
New-CPObject -Name "MyNet" -Value "10.0.1.0/24"        # Creates a network
New-CPObject -Name "MyRange" -Value "10.0.1.1-10.0.1.5" # Creates an address range
New-CPObject -Name "MyDNS" -Value "example.com"         # Creates a DNS domain

# Create and manage groups
New-NetworkGroup -name "WebServers" -members @("WebServer01", "WebServer02")
Update-NetworkGroup -name "WebServers" -add -members @("WebServer03")
Test-IPInGroup -IP "10.0.1.10" -Group $webServersGroup

# Publish changes
Invoke-SessionPublish -WaitEnd
```

### Query access and NAT rules

```powershell
# Get the access rulebase
$rulebase = Get-AccessRulebase -name "Network" -package "Standard" -All

# Get the NAT rulebase with UID expansion
$natRules = Get-NatRulebase -package "Standard" -All -Flatten -ExpandUID

# Classify NAT rules
$natRules.rulebase | ForEach-Object { Get-NatRuleType -NatRule $_ }
```

### Install a policy

```powershell
# Install policy and wait for completion
Install-Policy -policy-package "Standard" -targets @("GW01", "GW02") -EndTask
```

### Execute commands on gateways

```powershell
# Get Gaia configuration
$config = Get-CPGaiaConfiguration -Firewall "GW01"

# Get routing table as structured objects
$routes = Get-CPRoutingTable -Firewall "GW01"
$routes | Where-Object Protocol -eq "Static"

# Get firmware version
$ver = Invoke-FwVer -Firewall "GW01"
Write-Host "Version: $($ver.version), Build: $($ver.build)"

# Run a custom bash command
$result = Invoke-CpridutilBash -Firewall "GW01" -Script "df -h"

# Check VPN tunnels
Invoke-VPNTu -Firewall "GW01" -ListIKE
```

### Work with services

```powershell
# Create a TCP service
New-TCPService -name "MyApp" -port "8443" -comments "Custom application port"

# Create a service group
New-ServiceGroup -name "MyAppServices" -members @("MyApp", "https")

# Publish and install
Invoke-SessionPublish -WaitEnd
Install-Policy -policy-package "Standard" -targets @("GW01") -EndTask
```

### Query logs

```powershell
$tf = [timeFrame]::new("last-hour")
$logs = Get-FilteredCheckPointLogs -server "mgmt.example.com" -port 443 `
    -session $session -filter "blade:Firewall" -timeframe $tf `
    -filterFunction { param($log) $log.action -eq "Drop" }
```

## API Pattern

All functions follow a consistent pattern:

1. Accept an optional `-ManagementInfo` connection object (defaults to `$Global:MgmtAPI` or `$Global:CPManagement`)
2. Build a request body from parameters
3. Call the Management API via `CallAPI()` or `CallAllPagesAPI()`
4. Return the API response object

```powershell
# Explicit connection
$hosts = Get-HostObject -ManagementInfo $myConnection -All

# Or use the global variable (set by Connect-ManagementAPI -GlobalVar)
$hosts = Get-HostObject -All
```

For cprid_util functions, a `-Firewall` parameter identifies the target gateway (by name or object).

## Module Structure

```
PSSomeCheckPointNPMThings/
├── PSSomeCheckPointNPMThings.psd1     # Module manifest
├── PSSomeCheckPointNPMThings.psm1     # Module loader
├── README.md                          # This file
├── LICENSE                            # PolyForm Noncommercial License 1.0.0
├── AccessControl/                     # Access layers, rulebases, NAT rules (9 functions)
│   ├── AccessLayer/
│   ├── AccessRule/
│   └── NatRules/
├── Class/                             # timeFrame class definition
├── Connect/                           # Authentication (2 functions)
├── Generic/                           # API helpers, rulebase flattening (3 functions)
├── Logs/                              # Log queries (2 functions)
├── Misc/                              # Utilities, object queries, caches, tasks (12 functions)
│   ├── Caches/
│   ├── Objects/
│   └── Task/
├── NetworkObjects/                    # Full CRUD for all object types (24 functions)
│   ├── AddressRange/
│   ├── CheckPointHost/
│   ├── DNSDomain/
│   ├── Gateway/
│   ├── Groups/
│   ├── Hosts/
│   ├── InteroperableDevices/
│   ├── Networks/
│   ├── Objects/
│   └── Tags/
├── Policy/                            # Policy packages & installation (2 functions)
├── Services/                          # TCP, UDP, service groups CRUD (12 functions)
│   ├── Groups/
│   ├── TCP/
│   └── UDP/
├── Session/                           # Publish, discard, logout (3 functions)
├── Users/                             # User groups (1 function)
│   └── UserGroup/
├── cprid_util/                        # Remote execution on gateways (19 functions)
└── dbedit/                            # Database edit commands (2 functions)
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
