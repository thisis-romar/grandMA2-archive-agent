# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project scaffold: `README.md`, `LICENSE` (MIT), and a `.gitignore`
  tuned for VM artifacts, PowerShell, MA installers/showfiles, secrets, and
  `results/` output.
- `docs/compatibility-audit.md` — the audit framework: critical constraints, the
  version matrix (3.9 → 2.0), per-interface test plans (showfiles, network, DMX,
  fixture/XML), known compatibility boundaries, and a results-matrix template.
- `scripts/gMA2_Compat_Harness.ps1` — VMware `vmrun` clone-per-version
  orchestrator (revert → start → test → stop → CSV) with `Test-*` hook stubs.
- `-DryRun` mode for the harness: exercises the full orchestration with no
  VMware, VMs, or MA software, emitting a sample results matrix to `results/`.
- Version-matrix branches now hyperlink to their official grandMA2 release notes;
  documented the EULA-gated archive download entry point.
- Community-health files: `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  this changelog, `.editorconfig`, issue/PR templates, and a `-DryRun` CI workflow.

### Changed
- README refactored for open-source use: badges, table of contents, status/scope
  callout, result-code legend, and cross-links into the audit doc.

### Fixed
- **Docs correctness:** grandMA2 has no native OSC (grandMA3 / third-party only);
  sACN (E1.31) support floor corrected to v2.4; enriched the onPC
  parameter-unlock model and other version boundaries.
- **Harness security:** removed the hardcoded guest password — credentials now
  resolve from `GMA2_GUEST_USER` / `GMA2_GUEST_PASS` env vars or an interactive
  `Get-Credential` prompt (`PSCredential`).
- **Harness robustness:** `Invoke-VmRun` now checks `$LASTEXITCODE` and throws on
  failure; `Stop-VM` is best-effort so it cannot mask a test error; the results
  column list has a single source of truth.

[Unreleased]: https://github.com/thisis-romar/grandMA2-archive-agent/commits/main
