function Get-FlattenedRulebase {
    <#
    .SYNOPSIS
        Flattens a nested rulebase into a single-level list.

    .DESCRIPTION
        Takes a rulebase that may contain nested sections (rules with a "rulebase" property)
        and flattens them into a single array. Each sub-rule gets a "section" property
        added with the parent section name.

    .PARAMETER rules
        The array of rulebase objects, potentially containing nested sections.

    .OUTPUTS
        System.Object[]. A flat array of rule objects with section names attached.

    .EXAMPLE
        $flatRules = Get-FlattenedRulebase -rules $rulebase.rulebase

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$rules
    )
    $aResult = @()
    foreach ($oRule in $rules) {
        if ($oRule.rulebase) {
            foreach ($oSubrule in $oRule.rulebase) {
                if ($oSubrule -is [PSCustomObject]) {
                    $oSubrule | Add-Member -NotePropertyName "section" -NotePropertyValue $oRule.name
                } else {
                    $oSubrule.section = $oRule.name
                }
                $aResult += $oSubrule
            }
        } else {
            $aResult += $oRule
        }
    }
    return $aResult
}