function Set-XliffTranslationUnit {
<#
.SYNOPSIS
    Updates target text and state for one or more XLIFF translation units.

.DESCRIPTION
    Sets **Target** and **State** on units supplied through the pipeline or
    loaded from **-Path**. When a unit still has a backing XML node, the change
    is applied immediately so the object can be exported with `Export-XliffFile`.

    Two usage patterns are supported:

    1. **Pipeline update** (recommended for batch edits):
           Import-XliffFile .\fr-FR.xlf |
               Set-XliffTranslationUnit -Id 'Customer.Name' -Target 'Client' -PassThru |
               Export-XliffFile .\fr-FR.xlf

    2. **Load-update-save** (single command against a file path):
           Set-XliffTranslationUnit -Path .\fr-FR.xlf -Id 'Customer.Name' -Target 'Client'

    Use **-Id** to limit updates to specific units. When omitted, every supplied
    unit is updated.

.PARAMETER InputObject
    Translation units to update.

.PARAMETER Path
    XLIFF file to load, update, and save in one operation.

.PARAMETER Id
    Optional id filter. Only matching units are updated.

.PARAMETER Target
    New target text. Empty string clears the target element.

.PARAMETER State
    New translation state. Defaults to `translated`.

.PARAMETER OutputPath
    Destination path when **-Path** is used. Defaults to **Path**.

.PARAMETER PassThru
    Returns updated units after changes are applied.

.OUTPUTS
    [XliffTranslationUnit[]]
        When `-PassThru` is specified.

.EXAMPLE
    Import-XliffFile .\Translations\Sample.xlf |
        Set-XliffTranslationUnit -Id 'Report 50000 - Label 1' -Target 'Solde du' -PassThru |
        Export-XliffFile .\Translations\Sample.xlf

    Updates one missing translation and saves the file.

.NOTES
    Author: XliffParser Contributors

    Valid states follow the XLIFF 1.2 target state vocabulary enforced by the
    parameter validation set.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject,

        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string[]]$Id,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Target,

        [ValidateSet('final', 'new', 'needs-adaptation', 'needs-l10n', 'needs-review', 'needs-review-adaptation', 'needs-review-l10n', 'needs-review-translation', 'needs-translation', 'signed-off', 'translated')]
        [string]$State = 'translated',

        [string]$OutputPath,

        [switch]$PassThru
    )

    begin {
        $units = [System.Collections.Generic.List[XliffTranslationUnit]]::new()
        $loadedFromPath = $false

        if ($Path) {
            foreach ($unit in Import-XliffFile -Path $Path) {
                $units.Add($unit)
            }
            $loadedFromPath = $true
        }
    }

    process {
        foreach ($unit in $InputObject) {
            $units.Add($unit)
        }
    }

    end {
        $updated = [System.Collections.Generic.List[XliffTranslationUnit]]::new()

        foreach ($unit in $units) {
            if ($Id -and $Id -notcontains $unit.Id) {
                if ($PassThru -and -not $loadedFromPath) {
                    $unit
                }
                continue
            }

            if ($PSCmdlet.ShouldProcess($unit.Id, 'Update XLIFF translation unit')) {
                $unit.Target = $Target
                $unit.State = $State

                if ($unit.XmlNode) {
                    [void](Set-XliffUnitTarget -UnitNode ([System.Xml.XmlElement]$unit.XmlNode) -Target $Target)
                    Set-XliffUnitState -UnitNode ([System.Xml.XmlElement]$unit.XmlNode) -State $State
                }

                $updated.Add($unit)
            }

            if ($PassThru -and -not $loadedFromPath) {
                $unit
            }
        }

        if ($loadedFromPath) {
            $destination = if ($OutputPath) { $OutputPath } else { $Path }
            if ($updated.Count -eq 0) {
                Write-Warning 'No translation units matched the supplied filter.'
            }

            $document = if ($units.Count -gt 0) { $units[0].XmlDocument } else { $null }
            if ($document) {
                [void](Save-XliffXmlDocument -Document $document -Path $destination)
            }

            if ($PassThru) {
                $units
            }
        }
    }
}
