function Get-XliffMissingTranslation {
<#
.SYNOPSIS
    Returns translation units that still need work.

.DESCRIPTION
    Filters units whose completion state is **Missing**. A unit is treated as
    missing when:

    - Target text is null, empty, or whitespace, or
    - Target state is `needs-translation`

    Use this command to build translator todo lists or pre-sync reports.

.PARAMETER InputObject
    Translation units to inspect from the pipeline.

.PARAMETER Path
    Optional `.xlf` file to import before filtering.

.OUTPUTS
    [XliffTranslationUnit[]]

.EXAMPLE
    Get-XliffMissingTranslation -Path .\Translations\Sample.xlf

.EXAMPLE
    Import-XliffFile .\Translations\Sample.xlf |
        Get-XliffMissingTranslation |
        Export-XliffCsv .\artifacts\missing.csv

.NOTES
    Author: XliffParser Contributors
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject,

        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    begin {
        $units = [System.Collections.Generic.List[XliffTranslationUnit]]::new()
        if ($Path) {
            foreach ($unit in Import-XliffFile -Path $Path) {
                $units.Add($unit)
            }
        }
    }

    process {
        foreach ($unit in $InputObject) {
            $units.Add($unit)
        }
    }

    end {
        foreach ($unit in $units) {
            if ((Get-XliffUnitCompletionState -Unit $unit) -eq 'Missing') {
                $unit
            }
        }
    }
}
