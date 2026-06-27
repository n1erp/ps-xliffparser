function Get-XliffStatistics {
<#
.SYNOPSIS
    Calculates translation completion statistics for XLIFF files or unit objects.

.DESCRIPTION
    Returns an **XliffParser.Statistics** object with:

    - **TotalTranslations**
    - **TranslatedCount**
    - **MissingCount**
    - **NeedsReviewCount**
    - **CompletionPercentage**

    Accepts either file paths or piped **XliffTranslationUnit** objects. When
    multiple paths are supplied, one statistics object is returned per file.

.PARAMETER InputObject
    Translation units to summarize from the pipeline.

.PARAMETER Path
    One or more `.xlf` files to summarize.

.OUTPUTS
    [pscustomobject]

.EXAMPLE
    Get-XliffStatistics -Path .\Translations\Systemization.fr-FR.xlf

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.fr-FR.xlf | Get-XliffStatistics

.NOTES
    Author: XliffParser Contributors

    A unit counts as missing when the target is empty/whitespace or the state is
    `needs-translation`. Review states such as `needs-review` are tracked separately.
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]$Path
    )

    begin {
        $pipelineUnits = [System.Collections.Generic.List[XliffTranslationUnit]]::new()
        $hasPipelineInput = $false
    }

    process {
        foreach ($item in $Path) {
            $units = @(Import-XliffFile -Path $item)
            $first = $units | Select-Object -First 1
            if ($first) {
                New-XliffStatistics -Units $units -Path (Resolve-XliffPath -Path $item) -SourceLanguage $first.SourceLanguage -TargetLanguage $first.TargetLanguage
            } else {
                New-XliffStatistics -Units @() -Path (Resolve-XliffPath -Path $item)
            }
        }

        foreach ($unit in $InputObject) {
            $hasPipelineInput = $true
            $pipelineUnits.Add($unit)
        }
    }

    end {
        if ($hasPipelineInput) {
            $first = $pipelineUnits | Select-Object -First 1
            if ($first) {
                New-XliffStatistics -Units $pipelineUnits.ToArray() -Path $first.Path -SourceLanguage $first.SourceLanguage -TargetLanguage $first.TargetLanguage
            } else {
                New-XliffStatistics -Units @()
            }
        }
    }
}
