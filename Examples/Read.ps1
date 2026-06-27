# Read.ps1
# Demonstrates Import-XliffFile — load XLIFF files as translation unit objects.
#
# Run from the repository root:
#   pwsh .\Examples\Read.ps1
#
# After installing from the Gallery, replace the Import-Module line with:
#   Import-Module XliffParser

Import-Module XliffParser

$samplePath = Join-Path $PSScriptRoot '..\Tests\Fixtures\Sample.xlf'
$sourcePath = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.g.xlf'

Write-Host "`n=== Basic import ===" -ForegroundColor Cyan
# Default: returns one XliffTranslationUnit object per <trans-unit>
$units = Import-XliffFile -Path $samplePath
$units | Format-Table Id, Source, Target, State, TargetLanguage -AutoSize

Write-Host "`n=== Import from pipeline ===" -ForegroundColor Cyan
# Accepts paths from the pipeline (e.g. Get-ChildItem *.xlf | Import-XliffFile)
@($samplePath) | Import-XliffFile | Measure-Object | Select-Object Count

Write-Host "`n=== Raw XML (advanced) ===" -ForegroundColor Cyan
# -RawXml returns the underlying XmlDocument instead of unit objects
$xml = Import-XliffFile -Path $samplePath -RawXml
Write-Host "Namespace: $($xml.DocumentElement.NamespaceURI)"

Write-Host "`n=== Streaming (large files) ===" -ForegroundColor Cyan
# -Streaming reads units one at a time — lower memory, no round-trip export
$streamCount = 0
Import-XliffFile -Path $sourcePath -Streaming | ForEach-Object { $streamCount++ }
Write-Host "Streamed $streamCount units from Systemization.g.xlf"

Write-Host "`n=== Access unit properties ===" -ForegroundColor Cyan
$first = $units | Select-Object -First 1
Write-Host "Id:             $($first.Id)"
Write-Host "Source:         $($first.Source)"
Write-Host "Target:         $($first.Target)"
Write-Host "State:          $($first.State)"
Write-Host "SourceLanguage: $($first.SourceLanguage)"
Write-Host "TargetLanguage: $($first.TargetLanguage)"
