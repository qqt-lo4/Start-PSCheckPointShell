function Where-Used {
    <#
    .SYNOPSIS
        Finds where a Check Point object is used across the management database.

    .DESCRIPTION
        Queries the Management API to find all references to an object (in rules, groups, etc.)
        identified by name or UID.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .OUTPUTS
        [PSCustomObject] Usage information showing where the object is referenced.

    .EXAMPLE
        Where-Used -name "WebServer01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [object]$InputObject
    )
    
}