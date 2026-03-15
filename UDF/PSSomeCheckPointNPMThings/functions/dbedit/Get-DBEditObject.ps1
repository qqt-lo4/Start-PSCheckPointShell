function Get-DBEditObject {
    <#
    .SYNOPSIS
        Retrieves an object definition in XML format from the Check Point management database using dbedit.

    .DESCRIPTION
        Executes a dbedit "print" command on the management server to retrieve a raw object
        definition from the specified table, and parses the output as XML.

    .PARAMETER ManagementInfo
        Check Point management server connection object. If null, uses the global connection.

    .PARAMETER Table_name
        Name of the database table (e.g., "network_objects").

    .PARAMETER Object_name
        Name of the object to retrieve.

    .OUTPUTS
        [System.Xml.XmlDocument] Object definition in XML format.

    .EXAMPLE
        Get-DBEditObject -Table_name "network_objects" -Object_name "GW01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    [CmdletBinding()]
    Param(
        [object]$ManagementInfo,
        [Parameter(Mandatory, Position = 0)]
        [string]$Table_name,
        [Parameter(Mandatory, Position = 1)]
        [string]$Object_name,
        [AllowNull()]
        [string]$WaitProgressMessage = "dbedit> printxml $Table_name $Object_name"
    )
    Begin {
        $oMgmtInfo = if ($ManagementInfo) { $ManagementInfo } else { $Global:MgmtAPI }
    }
    Process {
        return [xml](Invoke-DBedit -ManagementInfo $oMgmtInfo -Commands "printxml $Table_name $Object_name")
    }
}