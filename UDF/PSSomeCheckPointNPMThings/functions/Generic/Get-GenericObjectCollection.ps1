function Get-GenericObjectCollection {
    <#
    .SYNOPSIS
        Retrieves a paginated collection of objects from the Check Point Management API.

    .DESCRIPTION
        Generic function that wraps Check Point API calls to retrieve collections of objects
        with support for pagination, filtering, ordering, and automatic retrieval of all pages.
        Adds a Management reference to each returned object.

    .PARAMETER ManagementInfo
        The management server connection object. If not specified, uses the cached connection.

    .PARAMETER details-level
        The level of detail to return. Valid values: "uid", "standard", "full". Defaults to "standard".

    .PARAMETER limit
        Maximum number of results per page. Defaults to 50.

    .PARAMETER offset
        Number of results to skip. Defaults to 0.

    .PARAMETER filter
        A filter expression to narrow results.

    .PARAMETER order
        An ordering specification for the results.

    .PARAMETER show-membership
        When specified, includes group membership information.

    .PARAMETER Body
        A custom request body (hashtable, JSON string, or object) to use instead of function parameters.

    .PARAMETER AllObjectsProperty
        The property name(s) in the API response that contain the object collection. Defaults to "objects".

    .PARAMETER All
        When specified, retrieves all pages of results automatically.

    .PARAMETER APICommand
        The Check Point API command to execute (e.g., "show-hosts", "show-networks").

    .PARAMETER WriteProgressMessage
        A message to display in the progress bar during retrieval.

    .OUTPUTS
        PSObject. The API response with all requested pages merged.

    .EXAMPLE
        Get-GenericObjectCollection -APICommand "show-hosts" -All -ManagementInfo $mgmt

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [Parameter(ParameterSetName = "list")]
        [ValidateSet("uid", "standard", "full")]
        [string]${details-level} = "standard", 
        [Parameter(ParameterSetName = "list")]
        [int]$limit = 50,
        [Parameter(ParameterSetName = "list")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "list")]
        [string]$filter,
        [Parameter(ParameterSetName = "list")]
        [object]$order,
        [Parameter(ParameterSetName = "list")]
        [switch]${show-membership},
        [Parameter(ParameterSetName = "body")]
        [object]$Body,
        [string[]]$AllObjectsProperty = "objects",
        [switch]$All,
        [Parameter(Mandatory)]
        [string]$APICommand,
        [AllowEmptyString()]
        [string]$WriteProgressMessage = ""
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $hBody = if ($PSCmdlet.ParameterSetName -eq "body") {
            if ($Body -is [hashtable]) {
                $Body
            } elseif ($Body -is [string]) {
                $Body | ConvertFrom-Json | ConvertTo-Hashtable
            } else {
                $Body | ConvertTo-Hashtable
            }
        } else {
            $hParam = Get-FunctionParameters -RemoveParam @("All", "ManagementInfo", "APICommand", "AllObjectsProperty", "WriteProgressMessage")
            $hParam
        }
    }
    Process {
        # get requested page
        if ($WriteProgressMessage -ne "") {
            if ($All) {
                Write-Progress -Activity $WriteProgressMessage -Status "Page 1"
            } else {
                Write-Progress -Activity $WriteProgressMessage
            }
        }
        $apiResult = $oMgmtInfo.CallAPI($APICommand, $hBody)
        $oResult = $apiResult
        if ($All) {
            if ($offset -eq 0) {
                $hBodyTemplate = $hBody 
                $iLastPage = [Math]::Ceiling($apiResult.total / [int]$hBodyTemplate["limit"])
                for ($i = 1; $i -lt $iLastPage; $i++) {
                    if ($WriteProgressMessage -ne "") {
                        Write-Progress -Activity $WriteProgressMessage -PercentComplete (($i / $iLastPage) * 100) -Status "Page $($i + 1) / $($iLastPage + 1)"
                    }
                    $hBody = $hBodyTemplate
                    $hBody["offset"] = $i * $hBody["limit"]
                    $hBody = $hBody | ConvertTo-Json
                    $apiResult = $oMgmtInfo.CallAPI($APICommand, $hBody)
                    foreach($property in $AllObjectsProperty) {
                        $oResult.$property += $apiResult.$property
                    }
                }
                $oResult.to = $oResult.total
                if ($WriteProgressMessage -ne "") {
                    Write-Progress -Activity $WriteProgressMessage -Completed
                }
            } else {
                throw "Can't get all items if offset is greater than 0"
            }
        } else {
            if ($WriteProgressMessage -ne "") {
                Write-Progress -Activity $WriteProgressMessage -Completed
            }
        }
        foreach($property in $AllObjectsProperty) {
            foreach ($oObject in $oResult.$property) {
                $oObject | Add-Member -NotePropertyName "Management" -NotePropertyValue $oMgmtInfo
            }
        }
        return $oResult
    }
}