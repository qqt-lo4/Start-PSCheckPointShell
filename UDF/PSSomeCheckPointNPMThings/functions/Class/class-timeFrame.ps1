<#
.SYNOPSIS
    Represents a time frame for Check Point log queries.

.DESCRIPTION
    Defines a time frame used to filter Check Point logs. Supports predefined values
    (e.g., "last-7-days", "today", "all-time") or a custom date range with explicit
    start and end DateTime values. Custom dates are formatted for the Check Point API.

.NOTES
    Author  : Loïc Ade
    Version : 1.0.0
#>
class timeFrame {
    hidden [string]$value
    hidden [DateTime]$customStartDateTime
    hidden [DateTime]$customEndDateTime

    timeFrame([string]$value) {
        if ($value -in @("last-7-days", "last-hour", "today", "last-24-hours", "yesterday", "this-week", "this-month", "last-30-days", "all-time")) {
            $this.value = $value
        } else {
            throw [System.ArgumentException] "Invalid timeframe value"
        }
    }

    timeFrame([DateTime]$start, [DateTime]$end) {
        if ($start -ge $end) {
            throw [System.ArgumentException] "End date is before or equal start date"
        }
        $this.value = "custom"
        $this.customStartDateTime = $start
        $this.customEndDateTime = $end
    }

    [string] getStartString() {
        if ($this.isCustomValue()) {
            return $this.getAPIFormatDate($this.customStartDateTime)
        } else {
            throw [System.InvalidOperationException] "Date is not custom"
        }
    }

    [string] getEndString() {
        if ($this.isCustomValue()) {
            return $this.getAPIFormatDate($this.customEndDateTime)
        } else {
            throw [System.InvalidOperationException] "Date is not custom"
        }
    }

    [DateTime] getStart() {
        if ($this.isCustomValue()) {
            return $this.customStartDateTime
        } else {
            throw [System.InvalidOperationException] "Date is not custom"
        }
    }

    [DateTime] getEnd() {
        if ($this.isCustomValue()) {
            return $this.customEndDateTime
        } else {
            throw [System.InvalidOperationException] "Date is not custom"
        }
    }

    [boolean] isCustomValue() {
        return $this.value -eq "custom"
    }

    [string] getValue() {
        return $this.value
    }

    hidden [string] getAPIFormatDate([DateTime]$date) {
        return $date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffK")
    }
}