function Resolve-CPObjectIdentifier {
    <#
    .SYNOPSIS
    Détermine automatiquement si l'identifiant est un UID ou un name Check Point
    
    .PARAMETER Identifier
    L'identifiant de l'objet (UID ou name)
    
    .EXAMPLE
    Resolve-CPObjectIdentifier -Identifier "97aeb369-9aea-11d5-bd16-0090272ccb30"
    # Retourne: @{uid = "97aeb369-9aea-11d5-bd16-0090272ccb30"}
    
    .EXAMPLE
    Resolve-CPObjectIdentifier -Identifier "MonServeur-Web"
    # Retourne: @{name = "MonServeur-Web"}
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Identifier
    )
    
    # Regex pour UID Check Point (UUID format)
    $uidPattern = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    
    if ($Identifier -match $uidPattern) {
        return @{uid = $Identifier}
    }
    else {
        return @{name = $Identifier}
    }
}
