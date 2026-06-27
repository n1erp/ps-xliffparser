function Measure-XliffStringDistance {
    <#
    .SYNOPSIS
        Calculates Levenshtein distance between two strings.
    .DESCRIPTION
        Internal helper used by Search-XliffText -Fuzzy. Returns the minimum
        number of single-character edits required to transform Left into Right.
    #>
    param(
        [AllowNull()][string]$Left,
        [AllowNull()][string]$Right
    )

    $Left = if ($null -eq $Left) { '' } else { $Left }
    $Right = if ($null -eq $Right) { '' } else { $Right }

    $matrix = New-Object 'int[,]' ($Left.Length + 1), ($Right.Length + 1)
    for ($i = 0; $i -le $Left.Length; $i++) { $matrix[$i, 0] = $i }
    for ($j = 0; $j -le $Right.Length; $j++) { $matrix[0, $j] = $j }

    for ($i = 1; $i -le $Left.Length; $i++) {
        for ($j = 1; $j -le $Right.Length; $j++) {
            $cost = if ($Left[$i - 1] -eq $Right[$j - 1]) { 0 } else { 1 }
            $matrix[$i, $j] = [math]::Min(
                [math]::Min($matrix[$i - 1, $j] + 1, $matrix[$i, $j - 1] + 1),
                $matrix[$i - 1, $j - 1] + $cost
            )
        }
    }

    return $matrix[$Left.Length, $Right.Length]
}

function Search-XliffText {
<#
.SYNOPSIS
    Searches source and/or target text inside XLIFF translation units.

.DESCRIPTION
    Finds translation units whose **Source** or **Target** text matches a pattern.
    By default both fields are searched unless **-Source** or **-Target** is
    specified explicitly.

    Matching modes:

    - Default: case-insensitive substring search
    - **-Regex**: regular expression matching
    - **-CaseSensitive**: literal substring search with case sensitivity
    - **-Fuzzy**: lightweight Levenshtein distance matching via **-MaxDistance**

.PARAMETER InputObject
    Translation units to search.

.PARAMETER Path
    Optional `.xlf` file to import before searching.

.PARAMETER Pattern
    Text or regex pattern to find.

.PARAMETER Source
    Search only source text.

.PARAMETER Target
    Search only target text.

.PARAMETER Regex
    Treat **Pattern** as a regular expression.

.PARAMETER CaseSensitive
    Use case-sensitive matching.

.PARAMETER Fuzzy
    Enable fuzzy matching based on edit distance.

.PARAMETER MaxDistance
    Maximum Levenshtein distance allowed when **-Fuzzy** is used. Default: 2.

.OUTPUTS
    [pscustomobject]
        **XliffParser.SearchResult** records with **Id**, **Field**, **Text**, and **Unit**.

.EXAMPLE
    Search-XliffText -Path .\Translations\Systemization.fr-FR.xlf -Pattern 'Systemization' -Source

.EXAMPLE
    Search-XliffText -Path .\Translations\Systemization.fr-FR.xlf -Pattern '^Extension' -Target -Regex

.NOTES
    Author: XliffParser Contributors
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [XliffTranslationUnit[]]$InputObject,

        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern,

        [switch]$Source,

        [switch]$Target,

        [switch]$Regex,

        [switch]$CaseSensitive,

        [switch]$Fuzzy,

        [ValidateRange(0, 20)]
        [int]$MaxDistance = 2
    )

    begin {
        $units = [System.Collections.Generic.List[XliffTranslationUnit]]::new()
        if ($Path) {
            foreach ($unit in Import-XliffFile -Path $Path) {
                $units.Add($unit)
            }
        }
    }

    process {
        foreach ($unit in $InputObject) {
            $units.Add($unit)
        }
    }

    end {
        $searchSource = $Source -or (-not $Source -and -not $Target)
        $searchTarget = $Target -or (-not $Source -and -not $Target)

        foreach ($unit in $units) {
            $fields = @()
            if ($searchSource) { $fields += [pscustomobject]@{ Name = 'Source'; Value = $unit.Source } }
            if ($searchTarget) { $fields += [pscustomobject]@{ Name = 'Target'; Value = $unit.Target } }

            foreach ($field in $fields) {
                $value = if ($null -eq $field.Value) { '' } else { [string]$field.Value }
                $matched = $false

                if ($Fuzzy) {
                    $left = if ($CaseSensitive) { $value } else { $value.ToLowerInvariant() }
                    $right = if ($CaseSensitive) { $Pattern } else { $Pattern.ToLowerInvariant() }
                    $matched = (Measure-XliffStringDistance -Left $left -Right $right) -le $MaxDistance
                } elseif ($Regex) {
                    $options = if ($CaseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
                    $matched = [System.Text.RegularExpressions.Regex]::IsMatch($value, $Pattern, $options)
                } elseif ($CaseSensitive) {
                    $matched = $value.Contains($Pattern)
                } else {
                    $matched = $value.IndexOf($Pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                }

                if ($matched) {
                    [pscustomobject]@{
                        PSTypeName = 'XliffParser.SearchResult'
                        Id         = $unit.Id
                        Field      = $field.Name
                        Text       = $value
                        Unit       = $unit
                    }
                }
            }
        }
    }
}
