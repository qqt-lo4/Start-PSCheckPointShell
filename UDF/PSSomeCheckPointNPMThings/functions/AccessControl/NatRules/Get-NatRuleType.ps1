function Get-NatRuleType {
    <#
    .SYNOPSIS
        Determines the NAT rule type classification.

    .DESCRIPTION
        Analyzes a NAT rule object and classifies it as one of the following types:
        NoNat, InternalToPublic_Internal, InternalToInternal_Internal, or
        InternalToInternal_Public, based on the source, destination, and translation properties.

    .PARAMETER NatRule
        The NAT rule object to classify.

    .OUTPUTS
        System.String. The NAT rule type classification.

    .EXAMPLE
        Get-NatRuleType -NatRule $rule

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$NatRule
    )
    function Test-PublicObject {
        Param(
            [Parameter(Mandatory)]
            [object]$NetworkObect
        )
        if ($NetworkObect.Name -eq "Original") {
            return 2
        }
        $bResult = $false
        foreach ($oSource in $NetworkObect) {
            if ((Test-IsPrivateIP -IPAddress (Convert-CPObjectToString $oSource)) -eq "No") {
                $bResult = $true
            }    
        }
        return [int]$bResult
    }
    if (Test-IsNoNatRule $NatRule) {
        return "NoNat"
    } else {
        $iSrc = Test-PublicObject $NatRule."original-source"
        $iDst = Test-PublicObject $NatRule."original-destination"
        $iTransSrc = Test-PublicObject $NatRule."translated-source"
        if ($iTransSrc -eq 2) { 
            # cell with "Original"
            $iTransSrc = $iSrc
        }
        $iTransDst = Test-PublicObject $NatRule."translated-destination"
        if ($iTransDst -eq 2) {
            $iTransDst = $iDst
        }
        $iFlags = "" + $iSrc + $iDst + $iTransSrc + $iTransDst

        switch -Regex ($iFlags) {
            "^0.1.$"  { return "InternalToPublic_Public"     }
            "^11.0$"  { return "PublicToInternal_Public"     }
            "^0000$"  { return "InternalToInternal_Internal" }
            default   { return "Unknown: $mask"              }
        }
    }
}