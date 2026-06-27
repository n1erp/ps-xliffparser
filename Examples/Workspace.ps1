# Workspace.ps1
# Demonstrates Import-XliffWorkspace — scan a folder and summarize all XLIFF files.
#
# Run from the repository root:
#   pwsh .\Examples\Workspace.ps1

Import-Module (Join-Path $PSScriptRoot '..\XliffParser.psd1') -Force

$fixturesPath = Join-Path $PSScriptRoot '..\Tests\Fixtures'

Write-Host "`n=== Load entire translations folder ===" -ForegroundColor Cyan
$workspace = Import-XliffWorkspace -Path $fixturesPath

Write-Host "Root path: $($workspace.Path)"
Write-Host "Total units across all files: $($workspace.Statistics.TotalTranslations)"
$workspace.Statistics | Format-List TotalTranslations, TranslatedCount, MissingCount, CompletionPercentage

Write-Host "`n=== Per-file breakdown ===" -ForegroundColor Cyan
$workspace.Files |
    ForEach-Object {
        [pscustomobject]@{
            File             = Split-Path $_.Path -Leaf
            TargetLanguage   = $_.TargetLanguage
            Total            = $_.Statistics.TotalTranslations
            Translated       = $_.Statistics.TranslatedCount
            CompletionPct    = $_.Statistics.CompletionPercentage
        }
    } |
    Format-Table -AutoSize

Write-Host "`n=== Group by language ===" -ForegroundColor Cyan
$workspace.ByLanguage | Format-Table Language, Count -AutoSize

Write-Host "`n=== Group by app folder ===" -ForegroundColor Cyan
# App name is derived from the parent folder of each .xlf file
$workspace.ByApp | Format-Table App, Count -AutoSize

Write-Host "`n=== Access units from a specific file ===" -ForegroundColor Cyan
$sampleFile = $workspace.Files | Where-Object { $_.Path -like '*Sample.xlf' } | Select-Object -First 1
$sampleFile.Statistics | Format-List
$sampleFile.Units | Select-Object -First 2 Id, Source, Target | Format-Table -AutoSize
