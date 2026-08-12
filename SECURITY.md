# Security Policy

## Supported versions

This project is a compatibility-audit **framework + harness scaffold**, not a
released binary. Security fixes are applied to the `main` branch only.

## Reporting a vulnerability

Please report suspected vulnerabilities **privately** — do not open a public
issue for anything security-sensitive.

- Preferred: use GitHub's **private vulnerability reporting**
  (repository → **Security** tab → **Report a vulnerability**).
- Alternatively, email `security@<your-domain>`.

Please include a description, reproduction steps, affected file(s), and the
impact you observed. We aim to acknowledge reports within a few business days
and to agree on a disclosure timeline with you before any public detail.

## Handling secrets

This harness drives Windows guest VMs and therefore touches **login
credentials**. Follow these rules:

- **Never hardcode credentials.** `scripts/gMA2_Compat_Harness.ps1` resolves the
  guest login from the `GMA2_GUEST_USER` / `GMA2_GUEST_PASS` environment
  variables, or an interactive `Get-Credential` prompt — held as a
  `PSCredential`. Do not reintroduce a plaintext password.
- **Do not commit secrets.** `.gitignore` already excludes `*.env`,
  `*credentials*`, `*.pat`, `*.secret`, VM artifacts, MA installers/showfiles,
  and the `results/` output directory. Keep it that way.
- **Obtain MA software yourself.** grandMA2 onPC installers are EULA-gated and
  must never be committed or redistributed through this repository.

## Scope

In scope: the PowerShell harness, the audit documentation, and the CI workflow.
Out of scope: third-party MA Lighting software, VMware, and any tool you wire
into the `Test-*` hooks — report those to their respective vendors.
