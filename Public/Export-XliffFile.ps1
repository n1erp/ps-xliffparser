function Export-XliffFile {
<#
.SYNOPSIS
    Writes translation unit changes back to an XLIFF file.

.DESCRIPTION
    Applies in-memory changes from **XliffTranslationUnit** objects to their
    backing XML nodes, then saves the document to disk.

    Typical usage is to import, modify, and export in one pipeline:

        Import-XliffFile .\fr-FR.xlf |
            Set-XliffTranslationUnit -Id 'Table 1 - Field 1' -Target 'Client' -PassThru |
            Export-XliffFile -Path .\fr-FR.xlf

    The command preserves namespaces, `xsi:schemaLocation`, notes, attributes,
    and existing formatting wherever possible because it edits nodes in place
    rather than serializing new XML.

    If your input objects came from `Import-XliffFile -Streaming` or were created
    manually, supply **-TemplatePath** so the exporter can locate the matching
    `<trans-unit>` nodes by **Id**.

.PARAMETER InputObject
    Translation units to export. Usually piped from `Import-XliffFile` or
    `Set-XliffTranslationUnit`.

.PARAMETER Path
    Destination `.xlf` path. Parent directories are created automatically.

.PARAMETER TemplatePath
    Optional template `.xlf` file used when **InputObject** instances do not
    contain backing XML nodes.

.PARAMETER PassThru
    Returns the fully resolved output path after the file is saved.

.OUTPUTS
    [string]
        The saved file path when `-PassThru` is specified.

.EXAMPLE
    $units = Import-XliffFile .\Translations\Systemization.fr-FR.xlf
    $units | Export-XliffFile -Path .\Translations\Systemization.fr-FR.xlf

    Re-saves imported units without modification (useful after manual property edits).

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.fr-FR.xlf |
        Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde du' -PassThru |
        Export-XliffFile -Path .\Translations\Systemization.fr-FR.xlf

    Updates one target and writes the file back.

.NOTES
    Author: XliffParser Contributors

    Units that cannot be matched to a node in the target document are skipped
    with a warning instead of failing the entire export.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [XliffTranslationUnit[]]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateNotNullOrEmpty()]
        [string]$TemplatePath,

        [switch]$PassThru
    )

    begin {
        $units = [System.Collections.Generic.List[XliffTranslationUnit]]::new()
    }

    process {
        foreach ($unit in $InputObject) {
            $units.Add($unit)
        }
    }

    end {
        if ($units.Count -eq 0) {
            throw 'No translation units were provided.'
        }

        $document = $null
        if ($TemplatePath) {
            $document = Read-XliffXmlDocument -Path $TemplatePath
            $documentUnits = Get-XliffTranslationUnitsFromDocument -Document $document -Path (Resolve-XliffPath -Path $TemplatePath)
            $documentMap = $documentUnits | Get-XliffUnitMap
        } else {
            $document = $units[0].XmlDocument
            if (-not $document) {
                throw 'InputObject does not include backing XML. Provide -TemplatePath or use objects returned by Import-XliffFile without -Streaming.'
            }

            $documentMap = @{}
            foreach ($unit in $units) {
                if ($unit.Id) {
                    $documentMap[$unit.Id] = $unit
                }
            }
        }

        foreach ($unit in $units) {
            $targetUnit = if ($unit.XmlNode -and -not $TemplatePath) {
                $unit
            } elseif ($unit.Id -and $documentMap.ContainsKey($unit.Id)) {
                $documentMap[$unit.Id]
            } else {
                $null
            }

            if (-not $targetUnit -or -not $targetUnit.XmlNode) {
                Write-Warning "Skipping unit '$($unit.Id)' because it was not found in the target document."
                continue
            }

            [void](Set-XliffUnitTarget -UnitNode ([System.Xml.XmlElement]$targetUnit.XmlNode) -Target $unit.Target)
            Set-XliffUnitState -UnitNode ([System.Xml.XmlElement]$targetUnit.XmlNode) -State $unit.State
        }

        if ($PSCmdlet.ShouldProcess($Path, 'Save XLIFF file')) {
            $savedPath = Save-XliffXmlDocument -Document $document -Path $Path
            if ($PassThru) {
                $savedPath
            }
        }
    }
}