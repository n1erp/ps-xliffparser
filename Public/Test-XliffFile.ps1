function Test-XliffFile {
<#
.SYNOPSIS
    Validates an XLIFF file for common translation issues.

.DESCRIPTION
    Scans every `<trans-unit>` and returns structured **XliffParser.ValidationResult**
    objects for problems such as:

    - Missing or empty **Target** text
    - Duplicate **Id** values
    - Missing **Id**
    - Invalid target **State** values

    When no issues are found, a single informational `Valid` result is returned.

    Use **-FailOnMissing** in CI pipelines to stop the build when translations
    are incomplete:

        Test-XliffFile .\Translations\Systemization.fr-FR.xlf -FailOnMissing

.PARAMETER Path
    Path to one or more `.xlf` files. Accepts pipeline input.

.PARAMETER FailOnMissing
    Throws a terminating error when any unit has a missing or empty target.

.OUTPUTS
    [pscustomobject]
        One result per issue, or one `Valid` result when the file passes.

.EXAMPLE
    Test-XliffFile .\Translations\Systemization.fr-FR.xlf

    Lists validation findings for a language file.

.EXAMPLE
    Test-XliffFile .\Translations\Systemization.fr-FR.xlf -FailOnMissing

    Fails the command when untranslated entries remain.

.NOTES
    Author: XliffParser Contributors
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [switch]$FailOnMissing
    )

    process {
        foreach ($item in $Path) {
            $resolvedPath = Resolve-XliffPath -Path $item
            Write-Verbose "Validating XLIFF file '$resolvedPath'."
            $units = @(Import-XliffFile -Path $resolvedPath)
            $results = [System.Collections.Generic.List[object]]::new()
            $seen = @{}

            foreach ($unit in $units) {
                if ([string]::IsNullOrWhiteSpace($unit.Id)) {
                    $results.Add((New-XliffValidationResult -Rule 'IdRequired' -Severity 'Error' -Id $unit.Id -Path $resolvedPath -Message 'Translation unit id is missing.'))
                } elseif ($seen.ContainsKey($unit.Id)) {
                    $results.Add((New-XliffValidationResult -Rule 'DuplicateId' -Severity 'Error' -Id $unit.Id -Path $resolvedPath -Message "Duplicate translation unit id '$($unit.Id)'."))
                } else {
                    $seen[$unit.Id] = $true
                }

                if (Test-XliffTargetMissing -Unit $unit) {
                    $results.Add((New-XliffValidationResult -Rule 'MissingTarget' -Severity 'Error' -Id $unit.Id -Path $resolvedPath -Message "Translation unit '$($unit.Id)' has a missing or empty target."))
                }

                if (Test-XliffStateInvalid -Unit $unit) {
                    $results.Add((New-XliffValidationResult -Rule 'InvalidState' -Severity 'Error' -Id $unit.Id -Path $resolvedPath -Message "Translation unit '$($unit.Id)' has invalid state '$($unit.State)'."))
                }
            }

            if ($FailOnMissing -and ($results | Where-Object Rule -eq 'MissingTarget')) {
                throw "Missing translations were found in '$resolvedPath'."
            }

            if ($results.Count -eq 0) {
                New-XliffValidationResult -Rule 'Valid' -Severity 'Info' -Path $resolvedPath -Message 'No validation issues were found.'
            } else {
                $results
            }
        }
    }
}
