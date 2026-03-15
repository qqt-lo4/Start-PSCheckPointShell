function Test-IsInternalToInternalInternalNatRule {
    <#
    .SYNOPSIS
        Tests whether a NAT rule is an internal-to-internal rule with internal translation.

    .DESCRIPTION
        Checks if both the original source and destination are private IP addresses,
        and the translated destination is also a private IP address. Returns false
        if source or destination is "Any".

    .PARAMETER NatRule
        The NAT rule object to evaluate.

    .OUTPUTS
        System.Boolean. True if the rule matches the internal-to-internal (internal translation) pattern.

    .EXAMPLE
        Test-IsInternalToInternalInternalNatRule -NatRule $rule

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [object]$NatRule
    )
    if (($NatRule."original-source".name -eq "Any") -or ($NatRule."original-destination".name -eq "Any")) {
        return $false
    }
    $bSourceInternalIP = $true
    foreach ($oSource in $NatRule."original-source") {
        if ((Test-IsPrivateIP -IPAddress (Convert-CPObjectToString $oSource)) -eq "No") {
            $bSourceInternalIP = $false
        }    
    }
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
    $bResult = $bSourceInternalIP -and $bDestinationInternalIP -and $bTranslatedDestinationInternalIP
    return $bResult
}
