## Test it

```powershell
Invoke-Pester .\Tests
```

### Tests folder

```text
Tests/
├── Fixtures/          Sample and Business Central XLIFF files
├── Shared/            TestHelpers.ps1 (shared setup)
├── Import.Tests.ps1   Import, raw XML, streaming
├── Export.Tests.ps1   Export, CSV, JSON
├── Sync.Tests.ps1     Sync, compare
└── Validation.Tests.ps1  Validate, statistics, search, workspace
```

| File | What it checks |
| --- | --- |
| `Import.Tests.ps1` | Loads units from fixtures, raw XML, streaming, pipeline |
| `Export.Tests.ps1` | Saves changes, round-trip, CSV/JSON export |
| `Sync.Tests.ps1` | Adds/removes units, keeps translations, compares files |
| `Validation.Tests.ps1` | Missing targets, stats, search, get/set, workspace scan |

Fixtures: `Sample.xlf` (3 units), `Systemization.g.xlf` + `Systemization.fr-FR.xlf` (93 units).

## Help

```powershell
Get-Help Sync-XliffFile -Examples
Get-Command -Module XliffParser
```