# Update.ps1
# Demonstrates Set-XliffTranslationUnit and Export-XliffFile — edit targets and save XLIFF.
#
# Run from the repository root:
#   pwsh .\Examples\Update.ps1
#
# Workflow: Import -> Set (update in memory + XML) -> Export (write file)

Import-Module XliffParser

$source = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'
$output = Join-Path $env:TEMP 'XliffParser-Sample.updated.xlf'

Write-Host "`n=== Pipeline update (recommended) ===" -ForegroundColor Cyan
# -PassThru returns the updated units so you can pipe to Export-XliffFile
Import-XliffFile -Path $source |
    Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde du' -State translated -PassThru |
    Export-XliffFile -Path $output -PassThru

Write-Host "`n=== Verify the saved file ===" -ForegroundColor Cyan
$updated = Import-XliffFile -Path $output |
    Get-XliffTranslationUnit -Id 'Report 50000 - Label 1'
$updated | Format-List Id, Source, Target, State

Write-Host "`n=== Update multiple units ===" -ForegroundColor Cyan
# Omit -Id to update every unit passed on the pipeline (use carefully)
Import-XliffFile -Path $source |
    Set-XliffTranslationUnit -Id 'Page 21 - Action 1 - Property Caption' -Target 'Valider' -State translated -PassThru |
    Select-Object Id, Target, State

Write-Host "`n=== Direct file update (load, edit, save) ===" -ForegroundColor Cyan
# -Path loads the file, applies changes, and saves back in one command
# Use -OutputPath to write to a different file instead of overwriting
$directOutput = Join-Path $env:TEMP 'XliffParser-Sample.direct.xlf'
Set-XliffTranslationUnit `
    -Path $source `
    -OutputPath $directOutput `
    -Id 'Report 50000 - Label 1' `
    -Target 'Solde dû' `
    -State translated
Write-Host "Saved to $directOutput"
