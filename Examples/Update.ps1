# Update.ps1
# Demonstrates Set-XliffTranslationUnit — change target text and state on translation units.
#
# Run from the repository root:
#   pwsh .\Examples\Update.ps1
#
# To save changes to disk, pipe to Export-XliffFile (see ExportXliff.ps1).

Import-Module XliffParser

$source = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'

Write-Host "`n=== Update one unit on the pipeline ===" -ForegroundColor Cyan
# -PassThru returns the updated unit objects (backing XML is updated in memory)
Import-XliffFile -Path $source |
    Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde du' -State translated -PassThru |
    Format-List Id, Source, Target, State

Write-Host "`n=== Update by Id only (other units unchanged) ===" -ForegroundColor Cyan
$units = Import-XliffFile -Path $source
$updated = $units | Set-XliffTranslationUnit -Id 'Page 21 - Action 1 - Property Caption' -Target 'Valider' -State translated -PassThru
$updated | Where-Object Id -eq 'Page 21 - Action 1 - Property Caption' | Format-List Target, State
$updated | Where-Object Id -eq 'Table 18 - Field 1 - Property Caption' | Format-List Target, State

Write-Host "`n=== Direct file update (load, edit, save) ===" -ForegroundColor Cyan
# -Path loads the file, applies changes, and saves in one step
# Use -OutputPath to write to a different file instead of overwriting
$directOutput = Join-Path $env:TEMP 'XliffParser-Sample.direct.xlf'
Set-XliffTranslationUnit `
    -Path $source `
    -OutputPath $directOutput `
    -Id 'Report 50000 - Label 1' `
    -Target 'Solde dû' `
    -State translated
Write-Host "Saved to $directOutput"
