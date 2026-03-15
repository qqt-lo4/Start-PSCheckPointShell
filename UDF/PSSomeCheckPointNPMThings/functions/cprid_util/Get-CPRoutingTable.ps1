function Get-CPRoutingTable {
    <#
    .SYNOPSIS
        Retrieves and parses the routing table from a Check Point gateway via cprid_util.

    .DESCRIPTION
        Executes "show route" via clish on the gateway and parses the output into structured
        objects with destination, protocol, next hop, interface, cost, age, and description.
        Supports static, connected, OSPF, RIP, BGP, and IS-IS routes. Handles multi-line
        route entries.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Firewall
        Target gateway object or name.

    .PARAMETER WaitProgressMessage
        Optional progress message displayed while waiting.

    .PARAMETER Timeout
        Maximum wait time in seconds. Default: 60.

    .OUTPUTS
        [PSCustomObject[]] Route objects with properties: Destination, Network, PrefixLength,
        Protocol, Codes, NextHop, Interface, Cost, Age, IsDirectlyConnected, Description.

    .EXAMPLE
        Get-CPRoutingTable -Firewall "GW01"

    .EXAMPLE
        Get-CPRoutingTable -Firewall "GW01" | Where-Object { $_.Protocol -eq "Static" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory)]
        [object]$Firewall,
        [AllowNull()]
        [string]$WaitProgressMessage,
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timeout = 60
    )
    $oFirewall, $oMgmtInfo = Get-GatwayAndManagementFromCache -ManagementInfo $ManagementInfo -Firewall $Firewall
    $allLines = Invoke-CpridutilClish -ManagementInfo $oMgmtInfo -Firewall $oFirewall -Script "show route"

    $routes = @()
    $headerPassed = $false
    $currentRoute = $null
    
    foreach ($line in $allLines) {
        $trimmedLine = $line.Trim()
        
        # Ignorer toutes les lignes jusqu'à la première ligne vide (après l'en-tête)
        if (-not $headerPassed) {
            if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
                $headerPassed = $true
            }
            continue
        }
        
        # Ignorer les lignes vides après l'en-tête
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            continue
        }
        
        # Vérifier si c'est une ligne de continuation (commence par des espaces)
        if ($line -match '^\s{2,}(\S.*)$' -and $currentRoute) {
            # C'est une ligne de continuation
            $continuationText = $Matches[1].Trim()
            $currentRoute.RawDetails += " " + $continuationText
            
            # Parser les informations supplémentaires qui pourraient être sur cette ligne
            if ($continuationText -match 'via\s+(\S+)') {
                if (-not $currentRoute.NextHop) {
                    $currentRoute.NextHop = $Matches[1].TrimEnd(',')
                }
            }
            
            if ($continuationText -match ',\s*(\S+),') {
                if (-not $currentRoute.Interface) {
                    $currentRoute.Interface = $Matches[1]
                }
            }
            
            if ($continuationText -match 'cost\s+(\d+)') {
                if ($null -eq $currentRoute.Cost) {
                    $currentRoute.Cost = [int]$Matches[1]
                }
            }
            
            if ($continuationText -match 'age\s+(\d+)') {
                if ($null -eq $currentRoute.Age) {
                    $currentRoute.Age = [int]$Matches[1]
                }
            }
            
            if ($continuationText -match 'is directly connected,\s*(\S+)') {
                $currentRoute.IsDirectlyConnected = $true
                if (-not $currentRoute.Interface) {
                    $currentRoute.Interface = $Matches[1].Trim()
                }
            }
            
            continue
        }
        
        # Parser une nouvelle ligne de route
        # Format typique: "S     10.0.0.0/8        via 192.168.1.1, eth0, cost 0, age 123456"
        # ou: "C     192.168.1.0/24   is directly connected, eth1"
        
        if ($line -match '^\s*([CSORBID\*\+\>]+)\s+(\S+)\s+(.+)$') {
            # Si on avait une route en cours, l'ajouter à la liste
            if ($currentRoute) {
                $routes += $currentRoute
            }
            
            $codes = $Matches[1].Trim()
            $destination = $Matches[2].Trim()
            $details = $Matches[3].Trim()
            
            # Déterminer le protocole basé sur le code
            $protocol = switch -Regex ($codes) {
                'S' { 'Static' }
                'C' { 'Connected' }
                'O' { 'OSPF' }
                'R' { 'RIP' }
                'B' { 'BGP' }
                'I' { 'IS-IS' }
                'D' { 'Default' }
                default { 'Unknown' }
            }
            
            # Parser les détails
            $nextHop = $null
            $interface = $null
            $cost = $null
            $age = $null
            $isDirect = $false
            
            if ($details -match 'is directly connected,\s*(\S+)') {
                $isDirect = $true
                $interface = $Matches[1].Trim()
            }
            elseif ($details -match 'via\s+(\S+)') {
                $nextHop = $Matches[1].TrimEnd(',')
                
                if ($details -match ',\s*(\S+),') {
                    $interface = $Matches[1]
                }
            }
            
            if ($details -match 'cost\s+(\d+)') {
                $cost = [int]$Matches[1]
            }
            
            if ($details -match 'age\s+(\d+)') {
                $age = [int]$Matches[1]
            }
            
            # Séparer réseau et masque
            $network = $null
            $prefixLength = $null
            if ($destination -match '^(.+)/(\d+)$') {
                $network = $Matches[1]
                $prefixLength = [int]$Matches[2]
            }
            else {
                $network = $destination
            }
            
            # Créer l'objet (PSCustomObject mutable)
            $currentRoute = [PSCustomObject]@{
                Destination = $destination
                Network = $network
                PrefixLength = $prefixLength
                Protocol = $protocol
                Codes = $codes
                NextHop = $nextHop
                Interface = $interface
                Cost = $cost
                Age = $age
                IsDirectlyConnected = $isDirect
                Description = $null
                RawDetails = $details
            }
        }
    }
    
    # Ajouter la dernière route si elle existe
    if ($currentRoute) {
        $routes += $currentRoute
    }
    
    # Post-traitement : extraire la description du RawDetails
    foreach ($route in $routes) {
        $description = $null
        
        if ($route.IsDirectlyConnected) {
            # Pour les routes connectées : description après "is directly connected, <interface>"
            if ($route.RawDetails -match "is directly connected,\s*\S+\s+(.+)$") {
                $description = $Matches[1].Trim()
            }
        }
        else {
            # Pour les autres routes : description après "age <number>"
            if ($route.RawDetails -match "age\s+\d+\s+(.+)$") {
                $description = $Matches[1].Trim()
            }
            # Si pas d'age, essayer après l'interface
            elseif ($route.RawDetails -match ",\s*\S+,\s*cost\s+\d+\s+(.+)$") {
                $description = $Matches[1].Trim()
            }
        }
        
        $route.Description = $description
    }
    
    # Définir les propriétés par défaut à afficher
    $defaultDisplaySet = 'Destination', 'Protocol', 'NextHop', 'Interface', 'Description'
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    
    # Appliquer le format par défaut à chaque objet
    foreach ($route in $routes) {
        $route | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers -Force
    }
    return $routes
}