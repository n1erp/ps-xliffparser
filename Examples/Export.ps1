# Export.ps1
# Demonstrates Export-XliffCsv and Export-XliffJson — export for reviewers (not .xlf files).
# For saving XLIFF files, see ExportXliff.ps1 (Export-XliffFile).
#
# Run from the repository root:
#   pwsh .\Examples\Export.ps1

Import-Module XliffParser

$path = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'
$csvPath = Join-Path $env:TEMP 'XliffParser-Sample.csv'
$jsonPath = Join-Path $env:TEMP 'XliffParser-Sample.json'
$jsonCompactPath = Join-Path $env:TEMP 'XliffParser-Sample.compact.json'

$units = Import-XliffFile -Path $path

Write-Host "`n=== Export to CSV (Excel-friendly) ===" -ForegroundColor Cyan
# Columns: Id, Source, Target, State, Note
Export-XliffCsv -InputObject $units -Path $csvPath -PassThru
Get-Content $csvPath | Select-Object -First 4

Write-Host "`n=== Export to JSON (automation / indexing) ===" -ForegroundColor Cyan
# Pretty-printed UTF-8 JSON with language metadata
Export-XliffJson -InputObject $units -Path $jsonPath -PassThru

Write-Host "`n=== Compact JSON ===" -ForegroundColor Cyan
Export-XliffJson -InputObject $units -Path $jsonCompactPath -Compress -PassThru

Write-Host "`n=== Pipeline usage ===" -ForegroundColor Cyan
# Typical pattern: import a language file and export for translators
Import-XliffFile -Path $path | Export-XliffCsv -Path $csvPath
