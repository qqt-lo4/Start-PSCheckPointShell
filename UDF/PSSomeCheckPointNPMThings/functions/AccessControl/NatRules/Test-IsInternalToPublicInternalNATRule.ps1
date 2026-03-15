function Test-IsInternalToPublicInternalNATRule {
    <#
    .SYNOPSIS
        Tests whether a NAT rule is an internal-to-public rule with internal translation.

    .DESCRIPTION
        Checks if the original destination is a public IP address and the translated
        destination is a private IP address (static NAT). Returns false if the
        original destination is "Any".

    .PARAMETER NatRule
        The NAT rule object to evaluate.

    .OUTPUTS
        System.Boolean. True if the rule matches the internal-to-public (internal translation) pattern.

    .EXAMPLE
        Test-IsInternalToPublicInternalNATRule -NatRule $rule

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$NatRule
    )
    if ($NatRule."original-destination".name -eq "Any") {
        return $false
    }
    # $bSourceInternalIP = $true
    # foreach ($oSource in $NatRule."original-source") {
    #     if ((Test-IsPrivateIP -IPAddress (Convert-CPObjectToString $oSource)) -eq "No") {
    #         $bSourceInternalIP = $false
    #     }    
    # }
    $bDestinationInternalIP = $true
    foreach ($oDestination in $NatRule."original-destination") {
        if ((Test-IsPrivateIP -IPAddress (Convert-CPObjectToString $oDestination)) -eq "No") {
            $bDestinationInternalIP = $false
        }    
    }
    $bTranslatedDestinationInternalIP = if ($NatRule."translated-destination".name -eq "Original") {
        $false
    } else {
        (Test-IsPrivateIP -IPAddress (Convert-CPObjectToString $NatRule."translated-destination")) -eq "Yes"
    }

    $bResult = ($NatRule.method -eq "static") `
                -and $bSourceInternalIP `
                -and (-not $bDestinationInternalIP) `
                -and $bTranslatedDestinationInternalIP

    return $bResult
}
