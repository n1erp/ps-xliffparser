# Statistics.ps1
# Demonstrates Get-XliffStatistics and Get-XliffMissingTranslation.
#
# Run from the repository root:
#   pwsh .\Examples\Statistics.ps1

Import-Module (Join-Path $PSScriptRoot '..\XliffParser.psd1') -Force

$samplePath = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'
$translatedPath = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.fr-FR.xlf'

Write-Host "`n=== Statistics for a partial translation ===" -ForegroundColor Cyan
# Returns: TotalTranslations, TranslatedCount, MissingCount, NeedsReviewCount, CompletionPercentage
Get-XliffStatistics -Path $samplePath | Format-List

Write-Host "`n=== Statistics for a complete translation ===" -ForegroundColor Cyan
Get-XliffStatistics -Path $translatedPath | Format-List TotalTranslations, TranslatedCount, MissingCount, CompletionPercentage

Write-Host "`n=== Statistics from pipeline ===" -ForegroundColor Cyan
Import-XliffFile -Path $samplePath | Get-XliffStatistics | Format-List CompletionPercentage, MissingCount

Write-Host "`n=== List missing translations ===" -ForegroundColor Cyan
# Units with empty target or state needs-translation
Get-XliffMissingTranslation -Path $samplePath |
    Format-Table Id, Source, Target, State -AutoSize

Write-Host "`n=== Missing translations to CSV for translators ===" -ForegroundColor Cyan
$missingCsv = Join-Path $env:TEMP 'XliffParser-Sample.missing.csv'
Get-XliffMissingTranslation -Path $samplePath | Export-XliffCsv -Path $missingCsv -PassThru

Write-Host "`n=== Compare completion across files ===" -ForegroundColor Cyan
Get-XliffStatistics -Path $samplePath, $translatedPath |
    Format-Table Path, TotalTranslations, TranslatedCount, CompletionPercentage -AutoSize
