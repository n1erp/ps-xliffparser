# XliffParser

A PowerShell module for **XLIFF** files, especially **Business Central** `.xlf` localization.

## Install

```powershell
Install-Module XliffParser
Import-Module XliffParser
```

## Features

| Feature | Commands | Example |
| --- | --- | --- |
| Import XLIFF files | `Import-XliffFile` | [Examples/Read.ps1](Examples/Read.ps1) |
| Export XLIFF files | `Export-XliffFile` | [Examples/Update.ps1](Examples/Update.ps1) |
| Filter translation units | `Get-XliffTranslationUnit` | [Examples/Filter.ps1](Examples/Filter.ps1) |
| Update translations | `Set-XliffTranslationUnit` | [Examples/Update.ps1](Examples/Update.ps1) |
| Sync source → language file | `Sync-XliffFile` | [Examples/Sync.ps1](Examples/Sync.ps1) |
| Compare two XLIFF files | `Compare-XliffFile` | [Examples/Compare.ps1](Examples/Compare.ps1) |
| Validate translations | `Test-XliffFile` | [Examples/Validate.ps1](Examples/Validate.ps1) |
| Export for reviewers | `Export-XliffCsv`, `Export-XliffJson` | [Examples/Export.ps1](Examples/Export.ps1) |
| Search source/target text | `Search-XliffText` | [Examples/Search.ps1](Examples/Search.ps1) |
| Completion statistics | `Get-XliffStatistics`, `Get-XliffMissingTranslation` | [Examples/Statistics.ps1](Examples/Statistics.ps1) |
| Scan a translations folder | `Import-XliffWorkspace` | [Examples/Workspace.ps1](Examples/Workspace.ps1) |