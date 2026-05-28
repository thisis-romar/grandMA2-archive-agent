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
