function Sync-XliffFile {
<#
.SYNOPSIS
    Synchronizes a translated XLIFF file with a generated source XLIFF file.

.DESCRIPTION
    Keeps a language file aligned with a Business Central generated `.g.xlf`
    source file after captions, labels, pages, tables, or reports change.

    For each `<trans-unit>` in the source file:

    - **Missing in target** -> unit is copied into the target with an empty target
      and state `needs-translation` (or the value of **-NewUnitState**).
    - **Same id, different source** -> source text in the target is updated, the
      existing French translation is preserved, and the unit is marked for review.
    - **Same id, same source** -> existing target text and metadata are left alone.

    When **-RemoveObsolete** is specified, units that exist only in the target
    file are removed because they no longer exist in the generated source.

    This is the primary command for recurring localization maintenance:

        Sync-XliffFile `
            -SourcePath .\Translations\Systemization.g.xlf `
            -TargetPath .\Translations\Systemization.fr-FR.xlf `
            -RemoveObsolete `
            -PassThru

.PARAMETER SourcePath
    Generated source `.g.xlf` file produced by AL compilation.

.PARAMETER TargetPath
    Translated language file to update, for example `Systemization.fr-FR.xlf`.

.PARAMETER OutputPath
    Optional output path. Defaults to **TargetPath** (in-place update).

.PARAMETER RemoveObsolete
    Removes `<trans-unit>` entries from the target when their **Id** no longer
    exists in the source file.

.PARAMETER NewUnitState
    Target state assigned to newly added units. Default: `needs-translation`.

.PARAMETER ChangedSourceState
    Target state assigned when source text changed but an existing translation
    should be kept for review. Default: `needs-review`.

.PARAMETER PassThru
    Returns an **XliffParser.SyncReport** object describing added, removed, and
    source-changed units.

.OUTPUTS
    [pscustomobject]
        When `-PassThru` is specified. Properties include **AddedCount**,
        **RemovedCount**, **SourceChangedCount**, and string arrays for each change
        category.

.EXAMPLE
    Sync-XliffFile `
        -SourcePath .\Translations\Systemization.g.xlf `
        -TargetPath .\Translations\Systemization.fr-FR.xlf `
        -RemoveObsolete `
        -PassThru

    Updates the French file in place and returns a change report.

.EXAMPLE
    Sync-XliffFile `
        -SourcePath .\Translations\MyApp.g.xlf `
        -TargetPath .\Translations\MyApp.fr-FR.xlf `
        -OutputPath .\artifacts\MyApp.fr-FR.synced.xlf

    Writes a synchronized copy without overwriting the original target file.

.NOTES
    Author: XliffParser Contributors

    The target document structure (groups, notes, attributes) is preserved.
    New units are appended to the first `<group>` under `<body>`, matching
    Business Central XLIFF layout conventions.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath,

        [string]$OutputPath,

        [switch]$RemoveObsolete,

        [ValidateSet('new', 'needs-translation', 'translated')]
        [string]$NewUnitState = 'needs-translation',

        [ValidateSet('needs-review', 'needs-review-translation', 'needs-adaptation')]
        [string]$ChangedSourceState = 'needs-review',

        [switch]$PassThru
    )

    $resolvedSourcePath = Resolve-XliffPath -Path $SourcePath
    $resolvedTargetPath = Resolve-XliffPath -Path $TargetPath
    $destination = if ($OutputPath) { $OutputPath } else { $resolvedTargetPath }

    Write-Verbose "Loading source XLIFF '$resolvedSourcePath'."
    $sourceDocument = Read-XliffXmlDocument -Path $resolvedSourcePath
    Write-Verbose "Loading target XLIFF '$resolvedTargetPath'."
    $targetDocument = Read-XliffXmlDocument -Path $resolvedTargetPath

    $sourceUnits = @(Get-XliffTranslationUnitsFromDocument -Document $sourceDocument -Path $resolvedSourcePath)
    $targetUnits = @(Get-XliffTranslationUnitsFromDocument -Document $targetDocument -Path $resolvedTargetPath)
    $targetMap = $targetUnits | Get-XliffUnitMap
    $sourceMap = $sourceUnits | Get-XliffUnitMap

    $added = [System.Collections.Generic.List[string]]::new()
    $removed = [System.Collections.Generic.List[string]]::new()
    $sourceChanged = [System.Collections.Generic.List[string]]::new()
    $savedPath = $null

    foreach ($sourceUnit in $sourceUnits) {
        if (-not $sourceUnit.Id) {
            continue
        }

        if ($targetMap.ContainsKey($sourceUnit.Id)) {
            $targetUnit = $targetMap[$sourceUnit.Id]
            if ($targetUnit.Source -ne $sourceUnit.Source) {
                Write-Verbose "Source text changed for '$($sourceUnit.Id)'. Marking for review."
                $sourceNode = Ensure-XliffChildElement -Parent ([System.Xml.XmlElement]$targetUnit.XmlNode) -LocalName 'source'
                $sourceNode.InnerText = $sourceUnit.Source
                Set-XliffUnitState -UnitNode ([System.Xml.XmlElement]$targetUnit.XmlNode) -State $ChangedSourceState
                $sourceChanged.Add($sourceUnit.Id)
            }

            continue
        }

        Write-Verbose "Adding missing translation unit '$($sourceUnit.Id)'."
        [void](Import-XliffUnitNode -SourceUnitNode ([System.Xml.XmlElement]$sourceUnit.XmlNode) -TargetDocument $targetDocument -InitialTarget '' -InitialState $NewUnitState)
        $added.Add($sourceUnit.Id)
    }

    if ($RemoveObsolete) {
        foreach ($targetUnit in $targetUnits) {
            if ($targetUnit.Id -and -not $sourceMap.ContainsKey($targetUnit.Id)) {
                Write-Verbose "Removing obsolete translation unit '$($targetUnit.Id)'."
                Remove-XliffUnitNode -UnitNode $targetUnit.XmlNode
                $removed.Add($targetUnit.Id)
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($destination, 'Save synchronized XLIFF file')) {
        $savedPath = Save-XliffXmlDocument -Document $targetDocument -Path $destination
    }

    $report = [pscustomobject]@{
        PSTypeName          = 'XliffParser.SyncReport'
        SourcePath          = $resolvedSourcePath
        TargetPath          = $resolvedTargetPath
        OutputPath          = $savedPath
        AddedCount          = $added.Count
        RemovedCount        = $removed.Count
        SourceChangedCount  = $sourceChanged.Count
        Added               = $added.ToArray()
        Removed             = $removed.ToArray()
        SourceChanged       = $sourceChanged.ToArray()
    }

    if ($PassThru) {
        $report
    }
}