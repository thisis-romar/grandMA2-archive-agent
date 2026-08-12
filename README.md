# grandMA2-archive-agent

> Compatibility-audit tooling for certifying a third-party tool against every obtainable grandMA2 onPC release.

[![Harness dry-run](https://github.com/thisis-romar/grandMA2-archive-agent/actions/workflows/dryrun.yml/badge.svg)](https://github.com/thisis-romar/grandMA2-archive-agent/actions/workflows/dryrun.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![Platform: Windows + VMware](https://img.shields.io/badge/platform-Windows%20%2B%20VMware-0078D6)
![grandMA2 onPC 2.0→3.9](https://img.shields.io/badge/grandMA2%20onPC-2.0%E2%86%923.9-7E4DD2)
![Status: framework / scaffold](https://img.shields.io/badge/status-framework%20%2F%20scaffold-orange)

Because only one grandMA2 onPC version installs per Windows OS, compatibility testing requires **one
isolated environment per version**. This repo provides the audit plan and the VM-orchestration harness
that drives it across all four interfaces — showfiles, network protocol, DMX output, and fixture/XML.

## Contents

- [What this is](#what-this-is)
- [Status](#status)
- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
- [Demo (dry run)](#demo-dry-run)
- [Result codes](#result-codes)
- [Interfaces audited](#interfaces-audited)
- [Compatibility boundaries](#compatibility-boundaries)
- [Requirements](#requirements)
- [Limitations](#limitations)
- [License](#license)
- [Disclaimer](#disclaimer)

## What this is

A toolkit for certifying a third-party tool against every obtainable grandMA2 onPC build. The
[`docs/compatibility-audit.md`](docs/compatibility-audit.md) framework defines the constraints, the
version matrix (3.9 → 2.0, each linked to its release notes), and per-interface test plans; the
[`scripts/gMA2_Compat_Harness.ps1`](scripts/gMA2_Compat_Harness.ps1) harness drives a clone-per-version
VMware matrix (revert → start → test → stop → CSV).

## Status

This is an audit **framework + harness scaffold**, not a turnkey product:

- ✅ **`-DryRun` works today** — exercises the full orchestration and emits a sample results matrix with
  no VMware, VMs, or MA software (see [Demo](#demo-dry-run)).
- 🔌 **The four `Test-*` hooks are stubs** — you wire in your own tool's invocations to turn a run into a
  real certification pass.
- 🖥️ **A real audit needs** VMware Workstation, one Windows VM per version, and MA installers — plus MA
  hardware on the bridge for full DMX-output certification (parameter unlock).

## Repository layout

```
.
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   └── compatibility-audit.md      # full audit framework + version matrix + test plans
├── scripts/
│   └── gMA2_Compat_Harness.ps1     # VMware clone orchestrator + test-battery scaffold
└── results/                        # CSV/audit output (gitignored except .gitkeep)
```

## Quick start

1. Read [`docs/compatibility-audit.md`](docs/compatibility-audit.md) end to end — it defines the
   constraints, the [version matrix](docs/compatibility-audit.md#2-version-matrix) (3.9 → 2.0), and the
   per-interface test plans.
2. Build base VM images (Win10 for 3.x, Win7 for legacy 2.x), snapshot clean.
3. Obtain each archive build from MA Lighting and stage one clone per version.
4. Configure the paths at the top of [`scripts/gMA2_Compat_Harness.ps1`](scripts/gMA2_Compat_Harness.ps1)
   (and set `GMA2_GUEST_USER` / `GMA2_GUEST_PASS`, or let it prompt — credentials are never hardcoded).
5. Wire your tool into the four `Test-*` hook functions.
6. Run the harness; transcribe the CSV into the [results matrix](docs/compatibility-audit.md#6-results-matrix-fill-per-version--test).

## Demo (dry run)

To see the orchestration end to end **without VMware, real VMs, or MA software**, run with `-DryRun`. It
mocks every `vmrun` call, skips the boot waits, bypasses the `.vmx` check, and emits a realistic results
matrix:

```bash
pwsh ./scripts/gMA2_Compat_Harness.ps1 -DryRun
```

It walks the full version manifest (revert → start → test battery → stop per build), marks the
unobtainable 2.0–2.3 legacy rows as `BLK`, and writes a sample CSV to
`results/demo_results_<timestamp>.csv`. Sample output:

```
Build    BaseOS ProtocolEra A1 A2 A3 A4    A5 B1 B2  B3 B4    B5 C1 C2 C3  C4 D1 D2 D3 D4
3.9.61.5 Win10  post29      P  P  P  EXP-F P  P  N/A P  EXP-F P  P  P  N/A P  P  P  P  P
2.4.x    Win7   pre29       P  P  P  EXP-F P  P  N/A P  EXP-F P  P  P  N/A P  P  P  P  P
2.0.x    WinXP  pre29       BLK …                                              (installer unobtainable)
```

How to read the sample:

- `A4` / `B4` are **negative** tests (newer showfile in older onPC; cross-era MA-Net2 join) — a confirmed
  clean failure is the *pass*, recorded as `EXP-F`.
- `B2` (OSC) is `N/A` everywhere: grandMA2 has **no native OSC** (it's a grandMA3 feature / third-party
  plugin only).
- `C2` (sACN) passes from **v2.4** onward; the pre-2.4 builds (2.0–2.3) predate sACN and are unobtainable
  here anyway, so they show `BLK`.
- `C3` (DMX parameter-unlock) stays `N/A` because it needs real MA hardware.

Replacing the `Test-*` hook bodies with real invocations of your tool turns the same run into a genuine
certification pass.

## Result codes

| Code | Meaning |
|---|---|
| `P` | Pass |
| `F` | Fail — a real failure to investigate |
| `EXP-F` | Expected failure confirmed (a negative test behaving correctly) |
| `N/A` | Not applicable to this version |
| `BLK` | Blocked — build or base OS unobtainable |

Full legend and the per-version × per-test grid: [`docs` §6](docs/compatibility-audit.md#6-results-matrix-fill-per-version--test).

## Interfaces audited

| Interface | Version-sensitivity | Key boundary |
|---|---|---|
| Showfiles (`.show.gz`) | High | Forward-only format (newer won't open in older) |
| Network (MA-Net2 / telnet) | Extreme for MA-Net2 | Protocol break at 2.9; no native OSC |
| DMX output (Art-Net / sACN) | Low | sACN from v2.4; param unlock needs MA hardware |
| Fixture library / XML | Moderate | Schema + Carallon library deltas |

Detailed per-interface procedures and pass criteria: [`docs` §4](docs/compatibility-audit.md#4-per-interface-test-plans).

## Compatibility boundaries

Seed these as expected results (full detail in [`docs` §5](docs/compatibility-audit.md#5-known-compatibility-boundaries-seed-these-as-expected-results)):

- **MA-Net2 breaks at 2.9** — pre/post-2.9 cannot share a session.
- **grandMA1 compat mode removed at 3.0** — downgrade to 2.9.1.1 to regain it.
- **Showfiles are forward-only** — newer → older fails by design (a negative test, not a bug).
- **sACN (E1.31) from v2.4**; Art-Net throughout (Art-Net 3 from 3.1, RDM from 3.3).
- **No native OSC** in grandMA2 (grandMA3 / third-party only).
- **Save-as-grandMA3 converter** needs Windows 10 (not Parallels).
- **3.9.x is the final grandMA2 branch** (Feb 2025); MA's focus moved to grandMA3.

## Requirements

- VMware Workstation Pro (free for personal use; commercial use requires a paid entitlement) with `vmrun`
- Windows base images (Win10/Win7, optionally WinXP for pre-2.4)
- PowerShell 5.1+ (PowerShell 7 works for `-DryRun` on any platform)
- grandMA2 onPC installers obtained individually from
  [malighting.com](https://www.malighting.com/downloads/products/grandma2/) under their EULA

## Limitations

- Some pre-2.9 legacy installers may be unobtainable — those rows close as `BLK`.
- MA installers are not designed for silent unattended install; the per-version install step may be
  semi-attended.
- Full DMX-output certification needs real MA hardware (node/wing/NPU) on the bridged network for
  parameter unlock (bare onPC outputs 0 parameters). The virtual matrix fully covers showfile, XML, and
  protocol-handshake testing on its own.

## License

MIT — see [LICENSE](LICENSE).

## Disclaimer

Not affiliated with or endorsed by MA Lighting. "grandMA2" is a trademark of its respective owner. This
tooling does not redistribute MA software; operators obtain installers themselves under MA's license
terms.
