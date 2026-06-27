# Sync.ps1
# Demonstrates Sync-XliffFile — align a language file with a regenerated .g.xlf source.
#
# Run from the repository root:
#   pwsh .\Examples\Sync.ps1
#
# Typical Business Central flow:
#   AL compile -> MyApp.g.xlf  -->  Sync-XliffFile  -->  MyApp.fr-FR.xlf

Import-Module XliffParser

$source = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.g.xlf'
$target = Join-Path $PSScriptRoot '..\Tests\Fixtures\Systemization.fr-FR.xlf'
$output = Join-Path $env:TEMP 'XliffParser-Systemization.fr-FR.synced.xlf'

Write-Host "`n=== Basic sync ===" -ForegroundColor Cyan
# -PassThru returns a report: AddedCount, RemovedCount, SourceChangedCount
$report = Sync-XliffFile `
    -SourcePath $source `
    -TargetPath $target `
    -OutputPath $output `
    -PassThru

$report | Format-List SourcePath, TargetPath, OutputPath, AddedCount, RemovedCount, SourceChangedCount

Write-Host "`n=== Sync with obsolete removal ===" -ForegroundColor Cyan
# -RemoveObsolete deletes target units that no longer exist in the source .g.xlf
Sync-XliffFile `
    -SourcePath $source `
    -TargetPath $target `
    -OutputPath $output `
    -RemoveObsolete `
    -PassThru |
    Select-Object AddedCount, RemovedCount, SourceChangedCount

Write-Host "`n=== Customize states for new/changed units ===" -ForegroundColor Cyan
# -NewUnitState: state for units added from source (default: needs-translation)
# -ChangedSourceState: state when English text changed (default: needs-review)
Sync-XliffFile `
    -SourcePath $source `
    -TargetPath $target `
    -OutputPath $output `
    -NewUnitState needs-translation `
    -ChangedSourceState needs-review `
    -PassThru |
    Select-Object Added, SourceChanged

Write-Host "`n=== In-place sync (overwrite target file) ===" -ForegroundColor Cyan
# Omit -OutputPath to update TargetPath directly
# Sync-XliffFile -SourcePath $source -TargetPath $target -RemoveObsolete

Write-Host "Synced file written to: $output"
