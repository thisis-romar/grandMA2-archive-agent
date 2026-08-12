# Contributing

Thanks for your interest in improving **grandMA2-archive-agent**. This repo is a
compatibility-audit framework: the plan lives in
[`docs/compatibility-audit.md`](docs/compatibility-audit.md) and the automation
in [`scripts/gMA2_Compat_Harness.ps1`](scripts/gMA2_Compat_Harness.ps1).

## Getting set up

You only need PowerShell to work on the harness and run the demo:

```bash
pwsh ./scripts/gMA2_Compat_Harness.ps1 -DryRun
```

`-DryRun` mocks VMware, skips boot waits, and writes a sample matrix to
`results/` — no VMs or MA software required. A real audit additionally needs
VMware Workstation, one Windows VM per version, MA installers, and (for full DMX
output) MA hardware. See the [README](README.md#status) for the full picture.

## Coding conventions (PowerShell harness)

- Use **approved PowerShell verbs** (`Get-`, `Test-`, `Invoke-`, `Restore-`,
  `Stop-`, …). Check with `Get-Verb`.
- Run **PSScriptAnalyzer** before opening a PR and address warnings:
  ```powershell
  Install-Module PSScriptAnalyzer -Scope CurrentUser   # once
  Invoke-ScriptAnalyzer -Path scripts/gMA2_Compat_Harness.ps1
  ```
- **Never hardcode secrets.** Guest credentials come from `GMA2_GUEST_USER` /
  `GMA2_GUEST_PASS` or `Get-Credential` (see [SECURITY.md](SECURITY.md)).
- **Keep `-DryRun` working.** The CI workflow runs it on every push/PR; if you
  change the orchestration, verify the demo still completes and writes a CSV.

## Extending the test battery

The four `Test-*` hooks (`Test-Showfiles`, `Test-Network`, `Test-DMX`,
`Test-FixtureXML`) are stubs. Wire your tool in by replacing the non-dry-run
body of each, returning a hashtable of test-id → result code
(`P` / `F` / `EXP-F` / `N/A`). Keep the dry-run branch emitting a realistic
sample so CI and demos stay meaningful. If you add a test column, update the
single `$TestIds` list, the results matrix in `docs` §6, and the
[result-code legend](README.md#result-codes).

## Docs changes

When you change version-sensitivity facts (protocol eras, support floors,
boundaries), update **both** `docs/compatibility-audit.md` and any affected
README wording so they stay consistent.

## Workflow

1. Branch from `main` (e.g. `feat/…`, `fix/…`, `docs/…`).
2. Make focused commits with clear messages (imperative mood, e.g.
   "Add sACN capture to Test-DMX").
3. Update [`CHANGELOG.md`](CHANGELOG.md) under `## [Unreleased]`.
4. Open a PR into `main`, fill in the template, and confirm CI is green.

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
