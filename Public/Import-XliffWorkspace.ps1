function Import-XliffWorkspace {
<#
.SYNOPSIS
    Recursively imports every XLIFF file in a workspace folder.

.DESCRIPTION
    Scans a translations or repository folder for `.xlf` files, loads all units,
    and returns an **XliffParser.Workspace** summary object containing:

    - Per-file statistics and unit collections
    - **ByLanguage** grouping (for example `fr-FR`, `de-DE`)
    - **ByApp** grouping based on the parent folder name
    - Aggregate statistics across the entire workspace

    Useful for dashboards, localization audits, and multi-app Business Central
    solutions with several extensions under one repository.

.PARAMETER Path
    Root folder to scan recursively.

.OUTPUTS
    [pscustomobject]
        **XliffParser.Workspace**

.EXAMPLE
    Import-XliffWorkspace -Path .\Translations

.EXAMPLE
    $workspace = Import-XliffWorkspace -Path .\Translations
    $workspace.ByLanguage | Format-Table Language, Count

.NOTES
    Author: XliffParser Contributors
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path
    )

    $root = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $files = Get-ChildItem -Path $root -Filter '*.xlf' -File -Recurse
    $fileSummaries = [System.Collections.Generic.List[object]]::new()
    $allUnits = [System.Collections.Generic.List[XliffTranslationUnit]]::new()

    foreach ($file in $files) {
        Write-Verbose "Loading XLIFF workspace file '$($file.FullName)'."
        $units = @(Import-XliffFile -Path $file.FullName)
        foreach ($unit in $units) {
            $allUnits.Add($unit)
        }

        $first = $units | Select-Object -First 1
        $statistics = if ($first) {
            New-XliffStatistics -Units $units -Path $file.FullName -SourceLanguage $first.SourceLanguage -TargetLanguage $first.TargetLanguage
        } else {
            New-XliffStatistics -Units @() -Path $file.FullName
        }

        $appName = Split-Path -Leaf (Split-Path -Parent $file.FullName)
        $fileSummaries.Add([pscustomobject]@{
                Path           = $file.FullName
                App            = $appName
                SourceLanguage = $statistics.SourceLanguage
                TargetLanguage = $statistics.TargetLanguage
                Statistics     = $statistics
                Units          = $units
            })
    }

    $byLanguage = $fileSummaries |
        Group-Object TargetLanguage |
        ForEach-Object {
            [pscustomobject]@{
                Language = $_.Name
                Files    = $_.Group
                Count    = $_.Count
            }
        }

    $byApp = $fileSummaries |
        Group-Object App |
        ForEach-Object {
            [pscustomobject]@{
                App   = $_.Name
                Files = $_.Group
                Count = $_.Count
            }
        }

    $firstUnit = $allUnits | Select-Object -First 1
    $aggregateStatistics = if ($firstUnit) {
        New-XliffStatistics -Units $allUnits.ToArray() -Path $root -SourceLanguage $firstUnit.SourceLanguage
    } else {
        New-XliffStatistics -Units @() -Path $root
    }

    [pscustomobject]@{
        PSTypeName = 'XliffParser.Workspace'
        Path       = $root
        Files      = $fileSummaries
        ByLanguage = $byLanguage
        ByApp      = $byApp
        Statistics = $aggregateStatistics
    }
}
