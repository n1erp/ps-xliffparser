# Classifies a unit as Translated, Missing, or NeedsReview for statistics commands.
function Get-XliffUnitCompletionState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [XliffTranslationUnit]$Unit
    )

    if (Test-XliffTargetMissing -Unit $Unit) {
        return 'Missing'
    }

    if ($Unit.State -in @('needs-review', 'needs-review-adaptation', 'needs-review-l10n', 'needs-review-translation', 'needs-adaptation', 'needs-l10n')) {
        return 'NeedsReview'
    }

    if ($Unit.State -eq 'needs-translation') {
        return 'Missing'
    }

    return 'Translated'
}

# Builds the XliffParser.Statistics result object returned by Get-XliffStatistics.
function New-XliffStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [XliffTranslationUnit[]]$Units,

        [string]$Path,

        [string]$SourceLanguage,

        [string]$TargetLanguage
    )

    $total = $Units.Count
    $translated = 0
    $missing = 0
    $needsReview = 0

    foreach ($unit in $Units) {
        switch (Get-XliffUnitCompletionState -Unit $unit) {
            'Translated' { $translated++ }
            'Missing' { $missing++ }
            'NeedsReview' { $needsReview++ }
        }
    }

    $completion = if ($total -gt 0) {
        [math]::Round(($translated / $total) * 100, 2)
    } else {
        0
    }

    [pscustomobject]@{
        PSTypeName            = 'XliffParser.Statistics'
        Path                  = $Path
        SourceLanguage        = $SourceLanguage
        TargetLanguage        = $TargetLanguage
        TotalTranslations     = $total
        TranslatedCount       = $translated
        MissingCount          = $missing
        NeedsReviewCount      = $needsReview
        CompletionPercentage  = $completion
    }
}
