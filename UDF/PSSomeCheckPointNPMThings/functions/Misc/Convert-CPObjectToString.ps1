function Convert-CPObjectToString {
    <#
    .SYNOPSIS
        Converts a Check Point object to its string representation based on object type.

    .DESCRIPTION
        Returns a human-readable string for a Check Point object, adapting the format
        based on the object type (host, network, range, group, etc.).

    .PARAMETER InputObject
        The Check Point object to convert.

    .OUTPUTS
        [String] String representation of the object.

    .EXAMPLE
        Convert-CPObjectToString -InputObject $hostObject

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-15) - Initial documented version
    #>
    Param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )
    switch ($InputObject.type) {
        "network" {
            return $InputObject.subnet4 + "/" + $InputObject."mask-length4"
        }
        "host" {
            return $InputObject."ipv4-address"
        }
        "address-range" {
            return $InputObject."ipv4-address-first" + "-" + $InputObject."ipv4-address-last"
        }
        "simple-gateway" {
            return $InputObject."ipv4-address"
        }
        "dns-domain" {
            return $InputObject.name.Substring(1)
        }
        "checkpoint-host" {
            return $InputObject."ipv4-address"
        }
        default {
            throw "Object not supported"
        }
    }
}
