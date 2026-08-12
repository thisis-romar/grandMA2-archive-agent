# ================================================================
#  gMA2_Compat_Harness.ps1
#  grandMA2 onPC compatibility audit - VM clone orchestrator
#  NOMAD AV QA
#
#  WHAT THIS DOES:
#    Drives a VMware Workstation clone-per-version test matrix.
#    For each version it: reverts to a clean snapshot, starts the
#    VM, invokes the operator's test battery, collects results,
#    stops the VM, and writes a CSV matrix.
#
#  WHAT THIS DOES NOT DO:
#    It does not download or install grandMA2 onPC (EULA-gated,
#    obtained manually) and it does not run the MA software itself.
#    The install step is staged into each clean snapshot beforehand.
#    The actual per-interface tests are YOUR tool - wired in at the
#    RUN-TEST-BATTERY hook below.
#
#  REQUIREMENTS:
#    - VMware Workstation Pro (vmrun.exe on PATH or set $VmRun)
#    - One linked clone per version, each with a 'clean-install'
#      snapshot (onPC + tool already installed)
#    - A test-runner the harness can invoke inside or against the guest
#
#  DEMO / DRY-RUN:
#    Run with -DryRun to exercise the full orchestration WITHOUT VMware,
#    real VMs, or MA software. vmrun calls are mocked, boot waits are
#    skipped, the .vmx existence check is bypassed, and the Test-* hooks
#    emit a realistic P / EXP-F / N/A matrix. Output CSV is written next
#    to the script under ../results/. Use this to demo the flow:
#        pwsh ./scripts/gMA2_Compat_Harness.ps1 -DryRun
# ================================================================

#Requires -Version 5.1

param(
    [switch]$DryRun   # mock VMware + emit sample results; no real VMs needed
)

# ---------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------
$VmRun     = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
$VmRoot    = "E:\VMs\gMA2-matrix"          # where the .vmx clones live
$Snapshot  = "clean-install"               # snapshot to revert to per pass
$ResultsCsv= "E:\IT_Logs\NOMAD\gMA2_compat_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# Guest VM login for runProgramInGuest. NEVER hardcode a password here.
# Real runs resolve credentials in Get-GuestCredential (below): env vars
# $env:GMA2_GUEST_USER / $env:GMA2_GUEST_PASS, else an interactive prompt.
$GuestUser = if ($env:GMA2_GUEST_USER) { $env:GMA2_GUEST_USER } else { "QAadmin" }
$GuestCredential = $null    # PSCredential, resolved lazily on first real use

# Canonical column order for the results matrix (single source of truth).
$TestIds = @('A1','A2','A3','A4','A5','B1','B2','B3','B4','B5','C1','C2','C3','C4','D1','D2','D3','D4')

# In dry-run, write the demo CSV beside the repo (results/) instead of E:\.
if ($DryRun) {
    $resultsDir = Join-Path (Split-Path -Parent $PSScriptRoot) "results"
    if (!(Test-Path $resultsDir)) { New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null }
    $ResultsCsv = Join-Path $resultsDir "demo_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

# Version manifest. Set 'Obtainable=$false' to auto-skip (logs BLK).
# 'Vmx' is the clone path; 'BaseOS' is informational.
$Manifest = @(
  @{ Build="3.9.61.5"; Branch="3.9"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_9_61_5\onPC-3_9_61_5.vmx"; Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.8.0";    Branch="3.8"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_8_0\onPC-3_8_0.vmx";       Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.7.0.5";  Branch="3.7"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_7_0_5\onPC-3_7_0_5.vmx";   Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.6.x";    Branch="3.6"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_6\onPC-3_6.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.5.x";    Branch="3.5"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_5\onPC-3_5.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.4.x";    Branch="3.4"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_4\onPC-3_4.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.3.x";    Branch="3.3"; BaseOS="Win10"; Vmx="$VmRoot\onPC-3_3\onPC-3_3.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.2.x";    Branch="3.2"; BaseOS="Win7";  Vmx="$VmRoot\onPC-3_2\onPC-3_2.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.1.x";    Branch="3.1"; BaseOS="Win7";  Vmx="$VmRoot\onPC-3_1\onPC-3_1.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="3.0.x";    Branch="3.0"; BaseOS="Win7";  Vmx="$VmRoot\onPC-3_0\onPC-3_0.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="2.9.1.x";  Branch="2.9"; BaseOS="Win7";  Vmx="$VmRoot\onPC-2_9\onPC-2_9.vmx";           Obtainable=$true  ; ProtocolEra="post29" }
  @{ Build="2.8.x";    Branch="2.8"; BaseOS="Win7";  Vmx="$VmRoot\onPC-2_8\onPC-2_8.vmx";           Obtainable=$true  ; ProtocolEra="pre29"  }
  @{ Build="2.7.x";    Branch="2.7"; BaseOS="Win7";  Vmx="$VmRoot\onPC-2_7\onPC-2_7.vmx";           Obtainable=$true  ; ProtocolEra="pre29"  }
  @{ Build="2.6.x";    Branch="2.6"; BaseOS="Win7";  Vmx="$VmRoot\onPC-2_6\onPC-2_6.vmx";           Obtainable=$true  ; ProtocolEra="pre29"  }
  @{ Build="2.5.x";    Branch="2.5"; BaseOS="Win7";  Vmx="$VmRoot\onPC-2_5\onPC-2_5.vmx";           Obtainable=$true  ; ProtocolEra="pre29"  }
  @{ Build="2.4.x";    Branch="2.4"; BaseOS="Win7";  Vmx="$VmRoot\onPC-2_4\onPC-2_4.vmx";           Obtainable=$true  ; ProtocolEra="pre29"  }
  @{ Build="2.3.x";    Branch="2.3"; BaseOS="WinXP"; Vmx="$VmRoot\onPC-2_3\onPC-2_3.vmx";           Obtainable=$false ; ProtocolEra="pre29"  }
  @{ Build="2.2.x";    Branch="2.2"; BaseOS="WinXP"; Vmx="$VmRoot\onPC-2_2\onPC-2_2.vmx";           Obtainable=$false ; ProtocolEra="pre29"  }
  @{ Build="2.1.x";    Branch="2.1"; BaseOS="WinXP"; Vmx="$VmRoot\onPC-2_1\onPC-2_1.vmx";           Obtainable=$false ; ProtocolEra="pre29"  }
  @{ Build="2.0.x";    Branch="2.0"; BaseOS="WinXP"; Vmx="$VmRoot\onPC-2_0\onPC-2_0.vmx";           Obtainable=$false ; ProtocolEra="pre29"  }
)

# Interfaces to exercise. Flip to $false to skip a dimension.
$Run = @{ Showfiles=$true; Network=$true; DMX=$true; FixtureXML=$true }

# ---------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------
$results = New-Object System.Collections.Generic.List[object]

function Log($msg, $color="Gray") { Write-Host "[$(Get-Date -Format HH:mm:ss)] $msg" -ForegroundColor $color }

# Resolve guest credentials once (real runs only). Prefers env vars; falls back
# to an interactive prompt. Returns $null in dry-run (no creds needed).
function Get-GuestCredential {
    if ($DryRun) { return $null }
    if ($script:GuestCredential) { return $script:GuestCredential }
    if ($env:GMA2_GUEST_PASS) {
        $sec = ConvertTo-SecureString $env:GMA2_GUEST_PASS -AsPlainText -Force
        $script:GuestCredential = [System.Management.Automation.PSCredential]::new($GuestUser, $sec)
    } else {
        $script:GuestCredential = Get-Credential -UserName $GuestUser -Message "grandMA2 guest VM login"
    }
    return $script:GuestCredential
}

function Invoke-VmRun {
    param([string[]]$VmArgs)
    if ($DryRun) { Log "    [dry-run] vmrun $($VmArgs -join ' ')" "DarkGray"; return }
    $out = & $VmRun @VmArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "vmrun failed (exit $LASTEXITCODE): $($VmArgs -join ' ') :: $out"
    }
    return $out
}

function Restore-VmAndStart($vmx) {
    Log "  revert -> $Snapshot" "Cyan"
    Invoke-VmRun @("-T","ws","revertToSnapshot",$vmx,$Snapshot) | Out-Null
    Log "  start" "Cyan"
    Invoke-VmRun @("-T","ws","start",$vmx,"nogui") | Out-Null
    if (-not $DryRun) { Start-Sleep -Seconds 30 }   # let the guest boot + onPC services settle
}

function Stop-VM($vmx) {
    # Best-effort: a failed stop must not mask the real test error or abort the run.
    Log "  stop" "Cyan"
    try { Invoke-VmRun @("-T","ws","stop",$vmx,"soft") | Out-Null }
    catch { Log "  stop failed: $_" "DarkYellow" }
}

# ---------------------------------------------------------------
# TEST BATTERY  (wire your tool in here)
# Each function returns a hashtable of test-id -> result string
# (P / F / EXP-F / N/A). Replace the placeholder bodies with real
# invocations of your tool against the running guest.
# ---------------------------------------------------------------
function Test-Showfiles($entry) {
    # A4 is a NEGATIVE test (newer showfile in older onPC) -> success = EXP-F.
    if ($DryRun) { return @{ A1="P"; A2="P"; A3="P"; A4="EXP-F"; A5="P" } }
    # TODO: run your .show.gz parse/export/round-trip tests against the guest.
    # Example pattern using runProgramInGuest (creds from Get-GuestCredential):
    #   $c = Get-GuestCredential
    #   Invoke-VmRun @("-T","ws","-gu",$c.UserName,"-gp",$c.GetNetworkCredential().Password,
    #     "runProgramInGuest",$entry.Vmx,"C:\tool\run-showfile-tests.exe","--out","C:\out\sf.json")
    # then copyFileFromGuestToHost and parse the JSON.
    return @{ A1="N/A"; A2="N/A"; A3="N/A"; A4="N/A"; A5="N/A" }
}

function Test-Network($entry) {
    # Group rule: only join a live MA-Net2 session with same ProtocolEra peers.
    # B4 cross-era is a NEGATIVE test -> success = clean no-join (EXP-F).
    if ($DryRun) {
        # grandMA2 has no native OSC (grandMA3 feature / third-party plugin only) -> B2 = N/A.
        return @{ B1="P"; B2="N/A"; B3="P"; B4="EXP-F"; B5="P" }
    }
    return @{ B1="N/A"; B2="N/A"; B3="N/A"; B4="N/A"; B5="N/A" }
}

function Test-DMX($entry) {
    # Requires real MA hardware on the bridge for parameter unlock (C3 stays N/A in dry-run).
    if ($DryRun) {
        $sacn = if ([version]$entry.Branch -ge [version]"2.4") { "P" } else { "N/A" }  # sACN (E1.31) support floor = v2.4
        return @{ C1="P"; C2=$sacn; C3="N/A"; C4="P" }
    }
    return @{ C1="N/A"; C2="N/A"; C3="N/A"; C4="N/A" }
}

function Test-FixtureXML($entry) {
    if ($DryRun) { return @{ D1="P"; D2="P"; D3="P"; D4="P" } }
    return @{ D1="N/A"; D2="N/A"; D3="N/A"; D4="N/A" }
}

# ---------------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------------
$logDir = Split-Path $ResultsCsv; if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
if (-not $DryRun -and -not (Test-Path $VmRun)) { Log "vmrun not found at $VmRun" "Red"; exit 1 }

Log "=== grandMA2 onPC compatibility audit ===" "Green"
if ($DryRun) { Log "*** DRY-RUN: VMware mocked, sample results emitted, no real VMs touched ***" "Magenta" }
Log "Versions in manifest: $($Manifest.Count)" "Green"

foreach ($entry in $Manifest) {
    Log "----- $($entry.Build)  [$($entry.BaseOS), $($entry.ProtocolEra)] -----" "Yellow"
    $row = [ordered]@{ Build=$entry.Build; Branch=$entry.Branch; BaseOS=$entry.BaseOS; ProtocolEra=$entry.ProtocolEra }

    if (-not $entry.Obtainable) {
        Log "  BLOCKED - installer not obtainable" "Red"
        $TestIds | ForEach-Object { $row[$_]="BLK" }
        $results.Add([pscustomobject]$row); continue
    }
    if (-not $DryRun -and -not (Test-Path $entry.Vmx)) {
        Log "  MISSING VMX: $($entry.Vmx)" "Red"
        $TestIds | ForEach-Object { $row[$_]="BLK" }
        $results.Add([pscustomobject]$row); continue
    }

    try {
        Restore-VmAndStart $entry.Vmx
        $r = @{}
        if ($Run.Showfiles)  { Log "  showfiles";  (Test-Showfiles  $entry).GetEnumerator() | % { $r[$_.Key]=$_.Value } }
        if ($Run.Network)    { Log "  network";    (Test-Network    $entry).GetEnumerator() | % { $r[$_.Key]=$_.Value } }
        if ($Run.DMX)        { Log "  dmx";        (Test-DMX        $entry).GetEnumerator() | % { $r[$_.Key]=$_.Value } }
        if ($Run.FixtureXML) { Log "  fixtureXML"; (Test-FixtureXML $entry).GetEnumerator() | % { $r[$_.Key]=$_.Value } }
        $r.GetEnumerator() | ForEach-Object { $row[$_.Key]=$_.Value }
        Log "  done" "Green"
    }
    catch {
        Log "  ERROR: $_" "Red"
        $row["error"]=$_.Exception.Message
    }
    finally {
        Stop-VM $entry.Vmx
    }
    $results.Add([pscustomobject]$row)
}

$results | Export-Csv -Path $ResultsCsv -NoTypeInformation
Log "=== complete -> $ResultsCsv ===" "Green"
