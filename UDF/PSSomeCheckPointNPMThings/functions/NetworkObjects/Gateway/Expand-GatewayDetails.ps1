function Expand-GatewayDetails {
    <#
    .SYNOPSIS
        Expands a Check Point gateway object with hardware and software details

    .DESCRIPTION
        Queries a gateway via its management server to collect firmware version, serial number,
        MAC address, model, jumbo hotfix, and cloud metadata (AWS/Azure).
        Enriches the existing gateway object in-place with the collected properties.

    .PARAMETER Gateway
        The gateway object to enrich. Must have 'Management', 'name' and 'operating-system' properties.

    .OUTPUTS
        [PSObject]. The gateway object enriched with detail properties.

    .EXAMPLE
        Get-GatewayDetails -Gateway $oGateway

    .EXAMPLE
        $aGateways | ForEach-Object { Get-GatewayDetails -Gateway $_ }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Gateway
    )
    Process {
        $oGateway = $Gateway
        $sFwVer = Invoke-FwVer -ManagementInfo $oGateway.Management -Firewall $oGateway.name -WaitProgressMessage "Getting fw ver for $($oGateway.name)"
        $oGateway | Set-Property "FwVer"     $sFwVer         | Out-Null
        $oGateway | Set-Property "CPVersion" $sFwVer.version | Out-Null
        $oGateway | Set-Property "Build"     $sFwVer.build   | Out-Null

        if ($oGateway.'operating-system' -eq "Gaia Embedded") {
            $oDiag = Invoke-ShowDiag -ManagementInfo $oGateway.Management -Firewall $oGateway.name -WaitProgressMessage "Getting show diag for $($oGateway.name)"
            $oGateway | Set-Property "ShowDiag" $oDiag                  | Out-Null
            $oGateway | Set-Property "Mac"      $oDiag."HW MAC address" | Out-Null
            $oGateway | Set-Property "Model"    $sFwVer.model           | Out-Null
            $oGateway | Set-Property "Serial"   $oDiag."Serial number"  | Out-Null
        } else {
            $sSerial = Invoke-CpridutilBash -ManagementInfo $oGateway.Management -Firewall $oGateway.name -WaitProgressMessage "Getting serial for $($oGateway.name)" -Script "cat /sys/class/dmi/id/product_serial"
            $oGateway | Set-Property "Serial" $sSerial | Out-Null
            try {
                $sJumboHotfix = Get-CPJumboHotfix -ManagementInfo $oGateway.Management -Firewall $oGateway.name -WaitProgressMessage "Getting jumbo hotfix for $($oGateway.name)"
                $oGateway | Set-Property "JumboHotfix" $sJumboHotfix | Out-Null
            } catch {
                
            }
            if ($sSerial -notlike "VMware*") {
                $sHardwareMac = Invoke-CpridutilBash -ManagementInfo $oGateway.Management -Firewall $oGateway.name -WaitProgressMessage "Getting mac for $($oGateway.name)" -Script "cat /sys/class/net/Mgmt/address"
                $oGateway | Set-Property "Mac" $sHardwareMac | Out-Null
            }
            $hAssetAll = Invoke-ShowAssetAll -ManagementInfo $oGateway.Management -Firewall $oGateway.name -WaitProgressMessage "Getting asset all for $($oGateway.name)"
            $oGateway | Set-Property "AssetAll" $hAssetAll | Out-Null
            if ($sSerial -like "VMware*") {
                $oGateway | Set-Property "Model" "VMWare" | Out-Null
            } else {
                if ($hAssetAll.Model) {
                    $oGateway | Set-Property "Model" $hAssetAll.Model | Out-Null
                } else {
                    try {
                        $sVendor = Get-CPSystemVendor -ManagementInfo $oGateway.Management -Firewall $oGateway.Name
                        if ($sVendor -like "Amazon*") {
                            $hAmazonData = Get-CPAWSMetadata -ManagementInfo $oGateway.Management -Firewall $oGateway.Name -MetadataURI "dynamic/instance-identity/document"
                            $oGateway | Set-Property "AWSData"  $hAmazonData                          | Out-Null
                            $oGateway | Set-Property "Model"    "Amazon $($hAmazonData.instanceType)" | Out-Null
                            $oGateway | Set-Property "Location" $hAmazonData.availabilityZone         | Out-Null
                        } elseif ($sVendor -eq "Microsoft Corporation") {
                            try {
                                $hAzureData = Get-CPAzureMetadata -ManagementInfo $oGateway.Management -Firewall $oGateway.Name
                                $sInstanceType = $hAzureData.compute.vmSize
                                $oGateway | Set-Property "Model"     "Azure $sInstanceType"                                                  | Out-Null
                                $oGateway | Set-Property "AzureData" $hAzureData                                                             | Out-Null
                                $oGateway | Set-Property "Location"  "$($hAzureData.compute.location) - $($hAzureData.compute.physicalZone)" | Out-Null
                            } catch {
                                # Firewall on Hyper-V on-premise
                            }
                        }
                    } catch {
                        Write-Host "fw ver failed for $($oGateway.name)" -ForegroundColor Red
                        Write-Host "reason: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
        }
        return $oGateway
    }
}
