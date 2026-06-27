function Compare-XliffFile {
<#
.SYNOPSIS
    Compares two XLIFF files and reports translation differences by unit id.

.DESCRIPTION
    Builds id-based maps for a reference file and a difference file, then emits
    one **XliffParser.Comparison** object per detected change:

    - **Added**       -> id exists only in the difference file
    - **Removed**     -> id exists only in the reference file
    - **SourceChanged** -> same id, different source text
    - **TargetChanged** -> same id, different target text

    Typical Business Central usage compares a generated `.g.xlf` file against a
    translated language file to see what translators still need to update:

        Compare-XliffFile `
            -ReferencePath .\Tests\Fixtures\Systemization.g.xlf `
            -DifferencePath .\Tests\Fixtures\Systemization.fr-FR.xlf

.PARAMETER ReferencePath
    Original or baseline XLIFF file. Aliases: **OriginalPath**, **SourcePath**.

.PARAMETER DifferencePath
    New or comparison XLIFF file. Aliases: **NewPath**, **TargetPath**.

.OUTPUTS
    [pscustomobject]
        One comparison record per change.

.EXAMPLE
    Compare-XliffFile `
        -ReferencePath .\Translations\Systemization.g.xlf `
        -DifferencePath .\Translations\Systemization.fr-FR.xlf |
        Group-Object ChangeType

    Summarizes how many targets differ between source and translation files.

.NOTES
    Author: XliffParser Contributors

    A fully translated language file compared against its `.g.xlf` source will
    usually report **TargetChanged** for every unit because generated source files
    do not contain target text.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('OriginalPath', 'SourcePath')]
        [ValidateNotNullOrEmpty()]
        [string]$ReferencePath,

        [Parameter(Mandatory)]
        [Alias('NewPath', 'TargetPath')]
        [ValidateNotNullOrEmpty()]
        [string]$DifferencePath
    )

    $referenceUnits = @(Import-XliffFile -Path $ReferencePath)
    $differenceUnits = @(Import-XliffFile -Path $DifferencePath)
    $referenceMap = $referenceUnits | Get-XliffUnitMap
    $differenceMap = $differenceUnits | Get-XliffUnitMap

    foreach ($unit in $differenceUnits) {
        if (-not $referenceMap.ContainsKey($unit.Id)) {
            [pscustomobject]@{
                PSTypeName        = 'XliffParser.Comparison'
                ChangeType        = 'Added'
                Id                = $unit.Id
                ReferenceSource   = $null
                DifferenceSource  = $unit.Source
                ReferenceTarget   = $null
                DifferenceTarget  = $unit.Target
            }
            continue
        }

        $reference = $referenceMap[$unit.Id]
        if ($reference.Source -ne $unit.Source) {
            [pscustomobject]@{
                PSTypeName        = 'XliffParser.Comparison'
                ChangeType        = 'SourceChanged'
                Id                = $unit.Id
                ReferenceSource   = $reference.Source
                DifferenceSource  = $unit.Source
                ReferenceTarget   = $reference.Target
                DifferenceTarget  = $unit.Target
            }
        }

        if ($reference.Target -ne $unit.Target) {
            [pscustomobject]@{
                PSTypeName        = 'XliffParser.Comparison'
                ChangeType        = 'TargetChanged'
                Id                = $unit.Id
                ReferenceSource   = $reference.Source
                DifferenceSource  = $unit.Source
                ReferenceTarget   = $reference.Target
                DifferenceTarget  = $unit.Target
            }
        }
    }

    foreach ($unit in $referenceUnits) {
        if (-not $differenceMap.ContainsKey($unit.Id)) {
            [pscustomobject]@{
                PSTypeName        = 'XliffParser.Comparison'
                ChangeType        = 'Removed'
                Id                = $unit.Id
                ReferenceSource   = $unit.Source
                DifferenceSource  = $null
                ReferenceTarget   = $unit.Target
                DifferenceTarget  = $null
            }
        }
    }
}
