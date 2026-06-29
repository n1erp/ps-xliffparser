# XliffParser Roadmap

Prioritized feature backlog for future releases. Items are ordered by **impact for Business Central localization** and **fit with the current module**.

Legend:
- **Impact** — how much day-to-day value for BC / XLIFF users
- **Effort** — rough implementation size (S / M / L)
- Status: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Priority 1 — Do first (highest impact)

These solve the most common pain after import/export/sync already exist.

| # | Feature | Proposed command(s) | Impact | Effort | Status |
| --- | --- | --- | --- | --- | --- |
| 1.1 | **Batch sync entire translations folder** | `Sync-XliffWorkspace` | **Very high** — after every AL compile, sync all `*.fr-FR.xlf` files against matching `.g.xlf` in one step | M | [ ] |
| 1.2 | **Placeholder / token validation** | `Test-XliffPlaceholders` | **Very high** — catches broken `%1`, `%2`, `{0}` in targets before publish (common BC bug) | S | [ ] |
| 1.3 | **Import translations from CSV** | `Import-XliffCsv` | **Very high** — closes the loop: export for reviewers → edit in Excel → merge back into `.xlf` | M | [ ] |
| 1.4 | **CI-friendly validation bundle** | `Test-XliffCi` | **High** — one command for pipelines: validate all languages, fail on missing, output summary | S | [ ] |
| 1.5 | **BC-aware filter by object type** | extend `Get-XliffTranslationUnit` | **High** — filter by Page/Table/Report/ToolTip using Xliff Generator notes already in files | S | [ ] |

### Why Priority 1 matters most

- **1.1** — Today users sync one file at a time; BC projects often have multiple apps and languages.
- **1.2** — Prevents runtime/UI bugs that normal “missing target” checks do not catch.
- **1.3** — You already export CSV; without import, translators must edit XML or use another tool.
- **1.4** — Low effort, high adoption for Gallery users and GitHub Actions.
- **1.5** — Uses metadata you already parse; helps translators work by object, not raw Id.

---

## Priority 2 — Strong value (next release)

| # | Feature | Proposed command(s) | Impact | Effort | Status |
| --- | --- | --- | --- | --- | --- |
| 2.1 | **Git diff integration** | `Compare-XliffGitDiff` | **High** — see translation impact between branches/commits in PR review | M | [ ] |
| 2.2 | **Glossary / terminology check** | `Test-XliffGlossary` | **High** — enforce “Customer → Client”, forbidden terms, approved wording | M | [ ] |
| 2.3 | **Untranslated = source detection** | extend `Test-XliffFile` | **Medium** — flag targets that equal source text (lazy translation) | S | [ ] |
| 2.4 | **HTML review report** | `Export-XliffHtmlReport` | **Medium** — shareable completion/missing/needs-review dashboard | M | [ ] |
| 2.5 | **Backup before sync** | `Backup-XliffFile` | **Medium** — snapshot `.xlf` before overwrite; safety net for translators | S | [ ] |
| 2.6 | **Copy translations from another language** | `Copy-XliffTranslation` | **Medium** — bootstrap `de-DE` from `fr-FR` as starting point | M | [ ] |
| 2.7 | **Export to Excel** | `Export-XliffExcel` | **Medium** — many translators prefer `.xlsx` over CSV | M | [ ] |

### Why Priority 2 is helpful

- Improves **review quality** (glossary, untranslated detection, HTML reports).
- Improves **team workflow** (git diff, backup, cross-language copy).
- **Excel export** is a frequent request in localization teams.

---

## Priority 3 — Automation & scale

| # | Feature | Proposed command(s) | Impact | Effort | Status |
| --- | --- | --- | --- | --- | --- |
| 3.1 | **Translation memory (TM)** | `Get-XliffTranslationMemoryMatch`, `Update-XliffFromMemory` | **High** (long term) — reuse past translations for new units | L | [ ] |
| 3.2 | **Machine translation** | `Invoke-XliffMachineTranslation` | **Medium** — Azure / DeepL / OpenAI for `needs-translation` only | L | [ ] |
| 3.3 | **Parallel workspace scan** | `Import-XliffWorkspace -Parallel` | **Medium** — faster on large mono-repos with many extensions | M | [ ] |
| 3.4 | **Duplicate source detection** | `Get-XliffDuplicateSource` | **Medium** — same English in many units; translate once, apply many | S | [ ] |
| 3.5 | **Incremental sync** | extend `Sync-XliffFile` | **Medium** — skip unchanged units via hash cache | M | [ ] |
| 3.6 | **Watch folder (dev mode)** | `Watch-XliffFolder` | **Low–Medium** — auto-sync when `.g.xlf` changes during AL dev | M | [ ] |

### Why Priority 3 comes later

- Higher complexity and external dependencies (API keys, TM storage).
- Big wins for **large teams** and **repeat work**, less critical for small extensions.

---

## Priority 4 — Ecosystem & polish

| # | Feature | Proposed command(s) | Impact | Effort | Status |
| --- | --- | --- | --- | --- | --- |
| 4.1 | **GitHub Actions / Azure DevOps templates** | docs + sample YAML | **Medium** — lowers barrier for Gallery adopters | S | [ ] |
| 4.2 | **AL project auto-detect** | `Get-XliffProjectLayout` | **Medium** — find `Translations/`, map apps to `.g.xlf` | M | [ ] |
| 4.3 | **Restore from backup** | `Restore-XliffFile` | **Low** — pair with backup feature | S | [ ] |
| 4.4 | **Power BI / analytics export** | `Export-XliffAnalytics` | **Low** — JSON schema for dashboards | S | [ ] |
| 4.5 | **VS Code extension** | separate repo | **Medium** (long term) — inline edit, sync, validate in editor | L | [ ] |
| 4.6 | **XLIFF 2.x read support** | extend `Import-XliffFile` | **Low** for BC — BC uses 1.2; useful for other tools | L | [ ] |

---

## Suggested release plan

### v1.1 — Automation essentials
- [ ] 1.1 `Sync-XliffWorkspace`
- [ ] 1.2 `Test-XliffPlaceholders`
- [ ] 1.3 `Import-XliffCsv`
- [ ] 1.4 `Test-XliffCi`

### v1.2 — Translator quality
- [ ] 1.5 BC note-based filtering
- [ ] 2.2 `Test-XliffGlossary`
- [ ] 2.3 Untranslated-equals-source check
- [ ] 2.4 `Export-XliffHtmlReport`
- [ ] 2.5 `Backup-XliffFile`

### v1.3 — Team & repo integration
- [ ] 2.1 `Compare-XliffGitDiff`
- [ ] 2.6 `Copy-XliffTranslation`
- [ ] 2.7 `Export-XliffExcel`
- [ ] 4.1 CI pipeline templates

### v2.0 — Smart translation
- [ ] 3.1 Translation memory
- [ ] 3.2 Machine translation providers
- [ ] 3.3 Parallel workspace processing

---

## Quick reference — top 5 most helpful overall

| Rank | Feature | Reason |
| --- | --- | --- |
| 1 | **Sync-XliffWorkspace** | Saves the most time after every BC build |
| 2 | **Test-XliffPlaceholders** | Prevents real production UI/runtime issues |
| 3 | **Import-XliffCsv** | Completes the translator round-trip you already started |
| 4 | **Test-XliffCi** | Easy adoption in CI; builds trust for Gallery users |
| 5 | **Test-XliffGlossary** | Keeps terminology consistent across large apps |

---

## Contributing

When implementing a roadmap item:

1. Add the public command under `Public/`
2. Add helpers under `Private/` if needed
3. Add Pester tests under `Tests/` with fixtures in `Tests/Fixtures/`
4. Add an example script under `Examples/`
5. Update `README.md` features table and this file (mark `[x]`)
