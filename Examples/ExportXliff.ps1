# ExportXliff.ps1
# Demonstrates Export-XliffFile — write translation units back to an XLIFF file.
#
# Run from the repository root:
#   pwsh .\Examples\ExportXliff.ps1
#
# Typical workflow: Import-XliffFile -> edit units -> Export-XliffFile
# See also: Update.ps1 (Set-XliffTranslationUnit) for changing target text first.

Import-Module XliffParser

$source = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'
$output = Join-Path $env:TEMP 'XliffParser-Sample.exported.xlf'

Write-Host "`n=== Export without changes (round-trip) ===" -ForegroundColor Cyan
# Re-save imported units to a new file — namespaces and metadata are preserved
Import-XliffFile -Path $source | Export-XliffFile -Path $output -PassThru

Write-Host "`n=== Export after updating a unit ===" -ForegroundColor Cyan
# Pipe updated units from Set-XliffTranslationUnit
$updatedOutput = Join-Path $env:TEMP 'XliffParser-Sample.exported-updated.xlf'
Import-XliffFile -Path $source |
    Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde du' -State translated -PassThru |
    Export-XliffFile -Path $updatedOutput -PassThru

Write-Host "`n=== Verify exported file ===" -ForegroundColor Cyan
Import-XliffFile -Path $updatedOutput |
    Get-XliffTranslationUnit -Id 'Report 50000 - Label 1' |
    Format-List Id, Source, Target, State

Write-Host "`n=== -PassThru returns the saved path ===" -ForegroundColor Cyan
$saved = Import-XliffFile -Path $source | Export-XliffFile -Path $output -PassThru
Write-Host "Saved to: $saved"
