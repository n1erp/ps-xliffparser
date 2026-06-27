function Get-XliffTranslationUnit {
<#
.SYNOPSIS
    Filters XLIFF translation units from the pipeline or a file path.

.DESCRIPTION
    Queries translation units by **Id**, **State**, **Source**, or **Target**.
    Accepts objects from `Import-XliffFile` through the pipeline, or loads a
    file directly when **-Path** is supplied.

    Wildcard matching is used by default (`-like`). Pass **-Regex** to treat
    **Id**, **Source**, and **Target** filters as regular expressions.

.PARAMETER InputObject
    Translation units to filter. Usually piped from `Import-XliffFile`.

.PARAMETER Path
    Optional `.xlf` path. When supplied, the file is imported before filtering.

.PARAMETER Id
    One or more translation unit ids to keep.

.PARAMETER State
    One or more target states to keep, for example `translated` or `needs-review`.

.PARAMETER Source
    Source text filter.

.PARAMETER Target
    Target text filter.

.PARAMETER Regex
    Treats **Id**, **Source**, and **Target** filters as regular expressions.

.OUTPUTS
    [XliffTranslationUnit[]]

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.fr-FR.xlf |
        Get-XliffTranslationUnit -State needs-review

    Returns units that translators should revisit.

.EXAMPLE
    Get-XliffTranslationUnit -Path .\Translations\Sample.xlf -Source '*Caption*'

    Loads a file and returns units whose source text matches a wildcard pattern.

.NOTES
    Author: XliffParser Contributors
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject,

        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string[]]$Id,

        [string[]]$State,

        [string]$Source,

        [string]$Target,

        [switch]$Regex
    )

    begin {
        $buffer = [System.Collections.Generic.List[XliffTranslationUnit]]::new()
        if ($Path) {
            foreach ($unit in Import-XliffFile -Path $Path) {
                $buffer.Add($unit)
            }
        }
    }

    process {
        foreach ($unit in $InputObject) {
            $buffer.Add($unit)
        }
    }

    end {
        foreach ($unit in $buffer) {
            if ($Id) {
                $idMatch = if ($Regex) {
                    ($Id | Where-Object { $unit.Id -match $_ } | Select-Object -First 1)
                } else {
                    $Id -contains $unit.Id
                }
                if (-not $idMatch) { continue }
            }

            if ($State -and $State -notcontains $unit.State) {
                continue
            }

            if ($Source) {
                $sourceMatch = if ($Regex) { $unit.Source -match $Source } else { $unit.Source -like $Source }
                if (-not $sourceMatch) { continue }
            }

            if ($Target) {
                $targetMatch = if ($Regex) { $unit.Target -match $Target } else { $unit.Target -like $Target }
                if (-not $targetMatch) { continue }
            }

            $unit
        }
    }
}
