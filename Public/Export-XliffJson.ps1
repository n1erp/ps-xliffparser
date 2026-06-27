function Export-XliffJson {
<#
.SYNOPSIS
    Exports translation units to UTF-8 JSON.

.DESCRIPTION
    Serializes **Id**, **Source**, **Target**, **State**, **Note**,
    **SourceLanguage**, and **TargetLanguage** to JSON for automation,
    search indexing, or downstream tooling.

.PARAMETER InputObject
    Translation units to export.

.PARAMETER Path
    Destination `.json` path.

.PARAMETER Compress
    Writes compact single-line JSON instead of pretty-printed JSON.

.PARAMETER PassThru
    Returns the saved file path.

.OUTPUTS
    [string]
        When `-PassThru` is specified.

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.fr-FR.xlf |
        Export-XliffJson .\artifacts\Systemization.fr-FR.json

.NOTES
    Author: XliffParser Contributors
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject,

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Compress,

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
        $data = $units | Select-Object Id, Source, Target, State, Note, SourceLanguage, TargetLanguage
        $json = $data | ConvertTo-Json -Depth 5 -Compress:$Compress
        $fullPath = Write-XliffUtf8File -Path $Path -Content $json

        if ($PassThru) {
            $fullPath
        }
    }
}
