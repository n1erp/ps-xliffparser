function Export-XliffCsv {
<#
.SYNOPSIS
    Exports translation units to a UTF-8 CSV review file.

.DESCRIPTION
    Writes **Id**, **Source**, **Target**, **State**, and **Note** columns to a
    CSV file that translators or reviewers can open in Excel, SharePoint, or a
    ticketing workflow.

.PARAMETER InputObject
    Translation units to export. Pipe from `Import-XliffFile`.

.PARAMETER Path
    Destination `.csv` path. Parent directories are created automatically.

.PARAMETER PassThru
    Returns the saved file path.

.OUTPUTS
    [string]
        When `-PassThru` is specified.

.EXAMPLE
    Import-XliffFile .\Translations\Systemization.fr-FR.xlf |
        Export-XliffCsv .\artifacts\Systemization.fr-FR.csv

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
        $fullPath = Assert-XliffOutputDirectory -Path $Path
        $units |
            Select-Object Id, Source, Target, State, Note |
            Export-Csv -Path $fullPath -NoTypeInformation -Encoding utf8

        if ($PassThru) {
            $fullPath
        }
    }
}
