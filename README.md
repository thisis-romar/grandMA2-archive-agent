# grandMA2-archive-agent

Automated retrieval and compatibility-audit tooling for archived grandMA2 onPC releases.

## What this is

A toolkit for certifying a third-party tool against every obtainable grandMA2 onPC
build. Because only one onPC version installs per Windows OS, compatibility testing
requires one isolated environment per version — this repo provides the audit plan and
the VM orchestration harness that drives it.

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

1. Read `docs/compatibility-audit.md` end to end — it defines the constraints,
   the version matrix (3.9 → 2.0), and the per-interface test plans.
2. Build base VM images (Win10 for 3.x, Win7 for legacy 2.x), snapshot clean.
3. Obtain each archive build from MA Lighting and stage one clone per version.
4. Configure the paths at the top of `scripts/gMA2_Compat_Harness.ps1`.
5. Wire your tool into the four `Test-*` hook functions.
6. Run the harness; transcribe the CSV into the results matrix.

## Demo (dry run — no VMware needed)

To see the orchestration end to end without VMware, real VMs, or MA software,
run the harness with `-DryRun`. It mocks every `vmrun` call, skips the boot
waits, bypasses the `.vmx` existence check, and emits a realistic
`P` / `EXP-F` / `N/A` / `BLK` matrix so you can demo the flow:

```bash
pwsh ./scripts/gMA2_Compat_Harness.ps1 -DryRun
```

It walks the full version manifest (revert → start → test battery → stop per
build), marks the unobtainable 2.0–2.3 legacy rows as `BLK`, and writes a
sample CSV to `results/demo_results_<timestamp>.csv`. Sample output:

```
Build    BaseOS ProtocolEra A1 A2 A3 A4    A5 B1 B2  B3 B4    B5 C1 C2  C3  C4 D1 D2 D3 D4
3.9.61.5 Win10  post29      P  P  P  EXP-F P  P  P   P  EXP-F P  P  P   N/A P  P  P  P  P
2.8.x    Win7   pre29       P  P  P  EXP-F P  P  N/A P  EXP-F P  P  N/A N/A P  P  P  P  P
2.0.x    WinXP  pre29       BLK …                                                        (unobtainable)
```

Notes on the sample values: `A4`/`B4` are *negative* tests (newer showfile in
older onPC; cross-era MA-Net2 join) so a confirmed clean failure shows as
`EXP-F`; `C3` (DMX parameter-unlock) stays `N/A` because it needs real MA
hardware; OSC (`B2`) and sACN (`C2`) read `N/A` on pre-3.0 builds. Replacing
the `Test-*` hook bodies with real invocations of your tool turns the same run
into a genuine certification pass.

## Interfaces audited

| Interface | Version-sensitivity | Key boundary |
|---|---|---|
| Showfiles (`.show.gz`) | High | Backward-incompatible format |
| Network (MA-Net2 / telnet / OSC) | Extreme for MA-Net2 | Protocol break at 2.9 |
| DMX output (Art-Net / sACN) | Low | Standards-based |
| Fixture library / XML | Moderate | Schema + Carallon library deltas |

## Requirements

- VMware Workstation Pro (free for personal use; commercial use requires a paid
  entitlement) with `vmrun`
- Windows base images (Win10/Win7, optionally WinXP for pre-2.4)
- PowerShell 5.1+
- grandMA2 onPC installers obtained individually from
  [malighting.com](https://www.malighting.com/downloads/products/grandma2/) under their EULA

## Honest limitations

- Some pre-2.9 legacy installers may be unobtainable — those rows close as `BLK`.
- MA installers are not designed for silent unattended install; the per-version
  install step may be semi-attended.
- Full DMX-output certification needs real MA hardware (node/wing/NPU) on the bridged
  network for parameter unlock. The virtual matrix fully covers showfile, XML, and
  protocol-handshake testing on its own.

## License

MIT — see [LICENSE](LICENSE).

## Disclaimer

Not affiliated with or endorsed by MA Lighting. "grandMA2" is a trademark of its
respective owner. This tooling does not redistribute MA software; operators obtain
installers themselves under MA's license terms.
