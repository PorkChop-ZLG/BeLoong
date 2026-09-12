# gen-is-disaster.ps1
# Upgrade the beloong:is_disaster master ledger tag.
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md section 2.4
#
# Behaviour:
#   - Keeps the existing 55 biomeswevegone:* entries UNCHANGED (no re-sort, no removal).
#   - Inserts the 5 core-mod custom biomes at the TOP of the values array.
#   - Does NOT add a "replace" field (preserves the current shape, so the existing
#     consumers keep working exactly as before).
#
# NOTE: 100% ASCII BY DESIGN (see gen-disaster-tags.ps1 header for rationale).
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-is-disaster.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-is-disaster.ps1 -Apply

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModsDir = Join-Path $Root 'mods'
$CoreJar = (Get-ChildItem -LiteralPath $ModsDir -File |
              Where-Object { $_.Name -like 'beloong-*.jar' } |
              Select-Object -First 1).FullName
$Target  = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\is_disaster.json'
$BwgNs   = 'biomeswevegone:'
$CoreNs  = 'beloong:'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

if (-not $CoreJar) { throw 'core mod jar not found under mods' }
if (-not (Test-Path -LiteralPath $Target)) { throw "target tag not found: $Target" }

Write-Host ""
Write-Host "=== 1. Read existing is_disaster ===" -ForegroundColor Cyan
$raw = [System.IO.File]::ReadAllText($Target, [System.Text.Encoding]::UTF8)
$obj = $raw | ConvertFrom-Json
$old = @($obj.values)
Write-Host "  existing entries: $($old.Count)"
# Idempotent: strip any custom biomes already present (they are re-inserted at the top),
# and work from the BWG-only remainder so re-runs converge instead of failing.
$oldCore = @($old | Where-Object { $_ -like "$CoreNs*" })
$oldBwg  = @($old | Where-Object { $_ -like "$BwgNs*" })
$other   = @($old | Where-Object { $_ -notlike "$CoreNs*" -and $_ -notlike "$BwgNs*" })
if ($other.Count) { Add-Fail "unexpected non-namespaced entries: $($other -join ', ')" }
if ($oldCore.Count) { Write-Host "  note: $($oldCore.Count) custom biomes already present (re-run); they will be re-inserted on top" -ForegroundColor DarkYellow }
if ($oldBwg.Count -ne 55) { Add-Fail "expected 55 BWG entries, found $($oldBwg.Count)" }
Write-Host "  existing: $($oldBwg.Count) BWG + $($oldCore.Count) custom"

Write-Host ""
Write-Host "=== 2. Custom biomes from core mod jar ===" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($CoreJar)
$coreAll = $zip.Entries |
    Where-Object { $_.FullName -match '^data/beloong/worldgen/biome/[^/]+\.json$' } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') } |
    Sort-Object
$zip.Dispose()
$gotCore  = @($coreAll | Where-Object { $_ -ne 'loong_palace' } | Sort-Object)
$wantCore = @('caves','frozen_ocean','ocean','river','windswept' | Sort-Object)
$d1 = @($wantCore | Where-Object { $gotCore -notcontains $_ })
$d2 = @($gotCore  | Where-Object { $wantCore -notcontains $_ })
if ($d1.Count -or $d2.Count) { Add-Fail "custom biome set mismatch: missing [$($d1 -join ',')] extra [$($d2 -join ',')]" }
else { Write-Host "  [OK] 5 custom biomes: $($gotCore -join ', ')" -ForegroundColor Green }

# ---------------------------------------------------------------- build
Write-Host ""
Write-Host "=== 3. Build new value list ===" -ForegroundColor Cyan
$newCore   = @($gotCore | ForEach-Object { "$CoreNs$_" })
$newValues = @($newCore) + @($oldBwg)     # custom at TOP, BWG untouched below
Write-Host "  custom at top : $($newCore.Count)"
Write-Host "  BWG below     : $($oldBwg.Count)"
Write-Host "  total         : $($newValues.Count)"
if ($newValues.Count -ne 60) { Add-Fail "expected 60 entries, got $($newValues.Count)" }

$dups = @($newValues | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($dups.Count) { Add-Fail "duplicate entries: $($dups -join ', ')" }

# ---------------------------------------------------------------- emit (no "replace" field, matches current shape)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('{')
$lines.Add('  "values": [')
for ($i = 0; $i -lt $newValues.Count; $i++) {
    $comma = if ($i -lt $newValues.Count - 1) { ',' } else { '' }
    $lines.Add("    `"$($newValues[$i])`"$comma")
}
$lines.Add('  ]')
$lines.Add('}')
$json = ($lines -join "`r`n") + "`r`n"

if ($Apply) {
    [System.IO.File]::WriteAllText($Target, $json, $Utf8NoBom)
    Write-Host ""
    Write-Host "  written: $Target" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  (dry-run; not written)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------- verify round-trip
if ($Apply) {
    $check = @((([System.IO.File]::ReadAllText($Target, [System.Text.Encoding]::UTF8)) | ConvertFrom-Json).values)
    if ($check.Count -ne 60) { Add-Fail "round-trip count = $($check.Count), expected 60" }
    $c1 = @($check | Where-Object { $_ -like "$CoreNs*" }).Count
    if ($c1 -ne 5) { Add-Fail "round-trip custom = $c1, expected 5" }
    if (-not ($check[0] -like "$CoreNs*")) { Add-Fail "round-trip: first entry is not a custom biome" }
    if ($check -contains 'beloong:loong_palace') { Add-Fail "round-trip: loong_palace must not be included" }
    $newBwg = @($check | Where-Object { $_ -like "$BwgNs*" })
    $diff = @(Compare-Object $oldBwg $newBwg)
    if ($diff.Count) { Add-Fail "BWG entries changed: $($diff.Count) differences" }
    else { Write-Host "  [OK] round-trip verified: 60 entries, 5 custom on top, 55 BWG unchanged" -ForegroundColor Green }
}

Write-Host ""
if ($script:fail.Count -gt 0) {
    Write-Host "=== FAILED: $($script:fail.Count) ===" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "[OK] all assertions passed" -ForegroundColor Green
exit 0
