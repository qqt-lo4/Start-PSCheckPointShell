function Test-IsNoNatRule {
    <#
    .SYNOPSIS
        Tests whether a NAT rule is a No-NAT rule.

    .DESCRIPTION
        Checks if all translated fields (service, source, destination) are set to "Original",
        indicating that no address translation is performed.

    .PARAMETER NatRule
        The NAT rule object to evaluate.

    .OUTPUTS
        System.Boolean. True if the rule is a No-NAT rule.

    .EXAMPLE
        Test-IsNoNatRule -NatRule $rule

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$NatRule
    )
    return ($NatRule."translated-service".name -eq "Original") `
      -and ($NatRule."translated-source".name -eq "Original") `
      -and ($NatRule."translated-destination".name -eq "Original")
}
