# grandMA2 onPC — Tool Compatibility Audit Framework

**Purpose:** Certify a third-party tool against every obtainable grandMA2 onPC release across four interfaces (showfiles, network protocol, DMX output, fixture library/XML).
**Scope:** All version branches including pre-2.9 legacy.
**Method:** One isolated Windows environment per version (forced by the one-onPC-per-OS constraint), driven by a clone + revert harness.
**Generated:** for NOMAD AV internal QA.

---

## 1. Critical constraints (read first)

| Constraint | Consequence for the audit |
|---|---|
| Only one grandMA2 onPC installs per Windows OS; installer overwrites prior build | Every version = its own VM clone. No co-install. |
| MA-Net2 network streaming protocol broke at **2.9** | Pre-2.9 and 2.9+ cannot share a session. Network tests must be grouped by protocol era. |
| Legacy 2.x targets Win7 (pre-2.4 may need WinXP); 3.x targets Win10/11 | Two (possibly three) base images required. |
| Installers are EULA-gated on malighting.com, downloaded individually | No bulk scraping. Operator places legitimately obtained installers in the install share. |
| Oldest builds may be absent from MA's current archive | Obtainability is tracked as a result, not assumed. |
| onPC parameter unlock needs real MA hardware on the network | DMX-output tests that require unlocked parameters need a node/wing/NPU reachable on the bridged net. |

---

## 2. Version matrix

Branch list per MA's release-notes index. Fill `Build` with the exact archive build number when obtained, `Obtainable` with Y/N, and `Base OS` with the image used.

| Branch | Example build | Target base OS | Obtainable (Y/N) | Notes |
|---|---|---|---|---|
| 3.9 | 3.9.61.5 / 3.9.63.6 | Win10 | | Current; 3.9.63.6 via gMA3 page |
| 3.8 | 3.8.0 | Win10 | | |
| 3.7 | 3.7.x | Win10 | | |
| 3.6 | 3.6.x | Win10 | | |
| 3.5 | 3.5.x | Win10 | | |
| 3.4 | 3.4.x | Win10 | | |
| 3.3 | 3.3.x | Win10 | | |
| 3.2 | 3.2.x | Win7/10 | | |
| 3.1 | 3.1.x | Win7 | | |
| 3.0 | 3.0.x | Win7 | | grandMA1 compat mode removed at 3.0 |
| 2.9 | 2.9.1.x | Win7 | | **MA-Net2 protocol boundary (post)** |
| 2.8 | 2.8.x | Win7 | | **MA-Net2 protocol boundary (pre)** |
| 2.7 | 2.7.x | Win7 | | |
| 2.6 | 2.6.x | Win7 | | |
| 2.5 | 2.5.x | Win7 | | |
| 2.4 | 2.4.x | Win7 | | |
| 2.3 | 2.3.x | WinXP/7 | | Availability risk |
| 2.2 | 2.2.x | WinXP/7 | | Availability risk |
| 2.1 | 2.1.x | WinXP/7 | | Availability risk |
| 2.0 | 2.0.x | WinXP/7 | | Availability risk |

Obtain archived builds from: malighting.com → Downloads → grandMA2 → **Software + Release Notes** → scroll → **Archive**.

---

## 3. Environment provisioning

### 3.1 Base images (build once, snapshot clean)
- `BASE-WIN10` — Windows 10 x64, latest updates, .NET present, tool's runtime deps installed, VMware tools/3D enabled. Snapshot: `clean`.
- `BASE-WIN7`  — Windows 7 SP1 x64, .NET 4.x, legacy onPC prerequisites. Snapshot: `clean`.
- `BASE-WINXP` *(only if certifying 2.0–2.3)* — WinXP SP3. Snapshot: `clean`.

### 3.2 Clone strategy
For each obtainable version:
1. Linked-clone the matching base → name `onPC-<build>` (e.g. `onPC-3_8_0`).
2. Install that single onPC build inside the clone.
3. Install/stage the tool under test (or point the harness at it over the share).
4. Snapshot `clean-install`.
5. All test passes start by reverting to `clean-install` for determinism.

### 3.3 Networking (only for network/DMX interfaces)
- Bridge each clone to the **Intel** NIC on the MA-Net range; assign a unique IP + station number.
- Enable promiscuous mode on the bridge so MA-Net2 multicast flows.
- Group network-session tests: **pre-2.9 cohort** and **2.9+ cohort** never share a live session.

---

## 4. Per-interface test plans

### A. Showfiles (`.show.gz`)
Format is backward-incompatible (newer showfiles won't open in older onPC).

| Test | Procedure | Pass criterion |
|---|---|---|
| A1 Parse | Tool reads a reference showfile saved by this version | All expected objects extracted, no parse errors |
| A2 Export round-trip | Tool writes a showfile; same version opens it | onPC loads with zero "conversion/repair" warnings |
| A3 Forward load | Tool's output from oldest version opens in this version | Loads or converts gracefully |
| A4 Backward load (negative) | Newer showfile opened in this version | Expected: documented failure — record exact error |
| A5 Object fidelity | Compare sequences, presets, fixtures, macros pre/post | No data loss |

Record the showfile schema/version string per onPC build — that's your real compatibility key, not the app version.

### B. Network protocol (MA-Net2 / telnet / OSC)

| Test | Procedure | Pass criterion |
|---|---|---|
| B1 Telnet remote | Connect port 30000, authenticate, issue command set | All commands ack; capture any unsupported keywords |
| B2 OSC in/out | Send/receive configured OSC; verify mapping | Round-trip correct (skip if version predates OSC) |
| B3 MA-Net2 join (same era) | Tool/station joins session within its protocol cohort | Joins, syncs, shows as station |
| B4 MA-Net2 cross-era (negative) | Attempt pre-2.9 ↔ 2.9+ session | Expected: no join — confirm clean failure, no hang |
| B5 Session role | Verify Master/Connected behavior, DMX from Master only | Matches documented session model |

### C. DMX output (Art-Net / sACN)
Standards-based — expect high version-stability; the value is confirming *where support begins*.

| Test | Procedure | Pass criterion |
|---|---|---|
| C1 Art-Net output | Capture packets; verify universes/values | Conforms to Art-Net spec, correct mapping |
| C2 sACN (E1.31) output | Capture packets (skip if version predates sACN) | Conforms to E1.31; priority/universe correct |
| C3 Parameter-unlock dependency | Confirm DMX only flows with MA hardware licensing params | Behavior matches parameter model |
| C4 Output parity | Same patch across versions yields identical DMX | Byte-identical frames |

### D. Fixture library / XML

| Test | Procedure | Pass criterion |
|---|---|---|
| D1 Fixture XML import | Tool-generated fixture type imports | Imports without schema error |
| D2 Export schema | Export a fixture type; diff schema vs prior versions | Document schema deltas |
| D3 Carallon library version | Record bundled library version per build | Logged |
| D4 Attribute mapping | Verify attributes/feature names survive (note MixColor rename era) | No attribute loss |

---

## 5. Known compatibility boundaries (seed these as expected results)

- **MA-Net2 break at 2.9** — network streaming protocol changed; pre/post 2.9 incompatible in-session.
- **grandMA1 compat mode removed at 3.0** — affects only legacy interop.
- **ColorDim/ColorMix → MixColor feature rename** (2.9 era) — macros/fixtures using old feature names need adjustment; relevant to interface D.
- **Showfile format** — forward-only; newer → older fails by design (interface A4 is a *negative* test, not a bug).
- **Save-as-grandMA3 converter** — present only in later 3.x; Win10 required for that path.
- **OS floor** — 3.x wants Win7+; legacy 2.x is Win7/XP-era.

---

## 6. Results matrix (fill per version × test)

Legend: `P` pass · `F` fail · `N/A` not applicable to version · `BLK` blocked (unobtainable build / OS) · `EXP-F` expected failure confirmed.

| Build | A1 | A2 | A3 | A4 | A5 | B1 | B2 | B3 | B4 | B5 | C1 | C2 | C3 | C4 | D1 | D2 | D3 | D4 |
|---|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| 3.9.x | | | | | | | | | | | | | | | | | | |
| 3.8.x | | | | | | | | | | | | | | | | | | |
| 3.7.x | | | | | | | | | | | | | | | | | | |
| 3.6.x | | | | | | | | | | | | | | | | | | |
| 3.5.x | | | | | | | | | | | | | | | | | | |
| 3.4.x | | | | | | | | | | | | | | | | | | |
| 3.3.x | | | | | | | | | | | | | | | | | | |
| 3.2.x | | | | | | | | | | | | | | | | | | |
| 3.1.x | | | | | | | | | | | | | | | | | | |
| 3.0.x | | | | | | | | | | | | | | | | | | |
| 2.9.x | | | | | | | | | | | | | | | | | | |
| 2.8.x | | | | | | | | | | | | | | | | | | |
| 2.7.x | | | | | | | | | | | | | | | | | | |
| 2.6.x | | | | | | | | | | | | | | | | | | |
| 2.5.x | | | | | | | | | | | | | | | | | | |
| 2.4.x | | | | | | | | | | | | | | | | | | |
| 2.3.x | | | | | | | | | | | | | | | | | | |
| 2.2.x | | | | | | | | | | | | | | | | | | |
| 2.1.x | | | | | | | | | | | | | | | | | | |
| 2.0.x | | | | | | | | | | | | | | | | | | |

---

## 7. Execution workflow

1. Build base images (§3.1), snapshot `clean`.
2. Obtain each archive build; update §2 obtainability.
3. For each build: clone → install onPC → stage tool → snapshot `clean-install`.
4. Run the harness (`gMA2_Compat_Harness.ps1`) — it reverts, launches, runs the test battery, logs results to CSV.
5. Transcribe CSV into §6 matrix; investigate every `F` (a real failure) vs `EXP-F` (expected boundary).
6. Summarize: lowest fully-passing version, first version each interface is supported, list of unobtainable builds.

---

## 8. Risks & honest limitations

- **Unobtainable legacy builds** — some 2.0–2.3 installers may simply be gone; those rows close as `BLK`.
- **Legacy OS activation** — Win7/XP base images need valid licensing; running them isolated/offline is advisable.
- **MA installers are not built for silent unattended install** — the harness automates the *lifecycle* (revert/start/stop/log); the install step may be semi-attended per version.
- **DMX/network tests need real MA hardware** for parameter unlock — pure-virtual covers showfile + XML + protocol-handshake testing, but full DMX output certification needs a node/wing/NPU on the bridge.
- **This framework does not itself run the software** — it's the plan + automation scaffold; a human/CI executes it on real Windows VMs.
