# Compare.ps1
# Demonstrates Compare-XliffFile — diff two XLIFF files by translation unit Id.
#
# Run from the repository root:
#   pwsh .\Examples\Compare.ps1

Import-Module (Join-Path $PSScriptRoot '..\XliffParser.psd1') -Force

$source = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.g.xlf'
$translated = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.fr-FR.xlf'
$sample = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'

Write-Host "`n=== Compare source vs translation ===" -ForegroundColor Cyan
# ReferencePath = baseline, DifferencePath = file to compare against it
# ChangeType: Added, Removed, SourceChanged, TargetChanged
$changes = Compare-XliffFile -ReferencePath $source -DifferencePath $translated
$changes | Group-Object ChangeType | Format-Table Name, Count -AutoSize

Write-Host "`n=== Show first few target differences ===" -ForegroundColor Cyan
$changes |
    Where-Object ChangeType -eq 'TargetChanged' |
    Select-Object -First 3 Id, ReferenceSource, DifferenceTarget |
    Format-Table -AutoSize

Write-Host "`n=== Compare before/after an edit ===" -ForegroundColor Cyan
# Useful to see what changed after updating a translation file
$changes = Compare-XliffFile -ReferencePath $sample -DifferencePath $sample
Write-Host "Identical files produce no changes: $($changes.Count -eq 0)"

Write-Host "`n=== Aliases ===" -ForegroundColor Cyan
# ReferencePath aliases: OriginalPath, SourcePath
# DifferencePath aliases: NewPath, TargetPath
