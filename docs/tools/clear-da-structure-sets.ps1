# clear-da-structure-sets.ps1
# Empty the two original dungeons_arise structure sets so their structures no longer
# generate outside beloong:disaster.
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md section 2.8
#
# RISK GATE: after this runs, the 33 migrated structures generate ONLY in beloong:disaster.
#            All preconditions are asserted before writing.
#
# Preconditions asserted:
#   1) beloong:disaster_ground_set.json exists with 29 members
#   2) beloong:disaster_underground_set.json exists with 4 members
#   3) all 33 member structure IDs exist in the DA jar
#   4) the 5 End-migrated structures keep their structure-JSON overrides (untouched here)
#
# NOTE: 100% ASCII BY DESIGN.
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\clear-da-structure-sets.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\clear-da-structure-sets.ps1 -Apply

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModsDir = Join-Path $Root 'mods'
$DaJar   = (Get-ChildItem -LiteralPath $ModsDir -File |
              Where-Object { $_.Name -like '*DungeonsArise-1.21.1-*.jar' } |
              Select-Object -First 1).FullName
$SetDir  = Join-Path $Root 'kubejs\data\beloong\worldgen\structure_set'
$OutDir  = Join-Path $Root 'kubejs\data\dungeons_arise\worldgen\structure_set'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

Write-Host ""
Write-Host "=== 1. Preconditions ===" -ForegroundColor Cyan

$gPath = Join-Path $SetDir 'disaster_ground_set.json'
$uPath = Join-Path $SetDir 'disaster_underground_set.json'
foreach ($p in @($gPath, $uPath)) {
    if (-not (Test-Path -LiteralPath $p)) { Add-Fail "missing required file: $p" }
}
if ($script:fail.Count) { Write-Host "ABORT: preconditions failed" -ForegroundColor Red; exit 1 }

$gj = Get-Content -LiteralPath $gPath -Raw -Encoding UTF8 | ConvertFrom-Json
$uj = Get-Content -LiteralPath $uPath -Raw -Encoding UTF8 | ConvertFrom-Json
$gc = @($gj.structures).Count
$uc = @($uj.structures).Count
Write-Host "  disaster_ground_set      : $gc members"
Write-Host "  disaster_underground_set : $uc members"
if ($gc -ne 29) { Add-Fail "ground members = $gc, expected 29" }
if ($uc -ne 4)  { Add-Fail "underground members = $uc, expected 4" }

$zip = [System.IO.Compression.ZipFile]::OpenRead($DaJar)
$jarIds = @($zip.Entries |
    Where-Object { $_.FullName -match '^data/dungeons_arise/worldgen/structure/[^/]+\.json$' } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') })
$origPlacement = @{}
foreach ($n in @('major_structures','minor_structures')) {
    $e = $zip.Entries | Where-Object { $_.FullName -eq "data/dungeons_arise/worldgen/structure_set/$n.json" }
    if (-not $e) { Add-Fail "original set not found in jar: $n"; continue }
    $r = New-Object System.IO.StreamReader($e.Open()); $t = $r.ReadToEnd(); $r.Close()
    $origPlacement[$n] = $t
}
$zip.Dispose()
if ($script:fail.Count) { Write-Host "ABORT: jar preconditions failed" -ForegroundColor Red; exit 1 }

$bad = @()
foreach ($e in (@($gj.structures) + @($uj.structures))) {
    $id = $e.structure.Replace('dungeons_arise:','')
    if ($jarIds -notcontains $id) { $bad += $id }
}
if ($bad.Count) { Add-Fail "member IDs not present in jar: $($bad -join ', ')" }
else { Write-Host "  [OK] all 33 member IDs exist in the jar" -ForegroundColor Green }

Write-Host ""
Write-Host "=== 2. Build emptied sets (placement preserved) ===" -ForegroundColor Cyan

function New-EmptiedSet([string]$origJson) {
    $o = $origJson | ConvertFrom-Json
    $p = $o.placement
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("{`r`n")
    [void]$sb.Append("  `"structures`": [],`r`n")
    [void]$sb.Append("  `"placement`": {`r`n")
    [void]$sb.Append("    `"type`": `"$($p.type)`",`r`n")
    [void]$sb.Append("    `"spacing`": $($p.spacing),`r`n")
    [void]$sb.Append("    `"separation`": $($p.separation),`r`n")
    [void]$sb.Append("    `"salt`": $($p.salt)`r`n")
    [void]$sb.Append("  }")
    if ($o.exclusion_zone) {
        [void]$sb.Append(",`r`n")
        [void]$sb.Append("  `"exclusion_zone`": {`r`n")
        [void]$sb.Append("    `"other_set`": `"$($o.exclusion_zone.other_set)`",`r`n")
        [void]$sb.Append("    `"chunk_count`": $($o.exclusion_zone.chunk_count)`r`n")
        [void]$sb.Append("  }`r`n")
    } else {
        [void]$sb.Append("`r`n")
    }
    [void]$sb.Append("}`r`n")
    return $sb.ToString()
}

$out = @{}
foreach ($n in @('major_structures','minor_structures')) {
    if (-not $origPlacement.ContainsKey($n)) { continue }
    $out[$n] = New-EmptiedSet $origPlacement[$n]
    $o = $origPlacement[$n] | ConvertFrom-Json
    $ex = if ($o.exclusion_zone) { $o.exclusion_zone.other_set } else { '(none)' }
    Write-Host "  $n : spacing=$($o.placement.spacing) separation=$($o.placement.separation) salt=$($o.placement.salt) exclusion=$ex"
}

if ($Apply) {
    if (-not [System.IO.Directory]::Exists($OutDir)) { [System.IO.Directory]::CreateDirectory($OutDir) | Out-Null }
    foreach ($n in $out.Keys) {
        [System.IO.File]::WriteAllText((Join-Path $OutDir "$n.json"), $out[$n], $Utf8NoBom)
        Write-Host "  written: $n.json" -ForegroundColor Green
    }
    foreach ($n in @('major_structures','minor_structures')) {
        $p = Join-Path $OutDir "$n.json"
        $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json
        $c = @($j.structures).Count
        if ($c -ne 0) { Add-Fail "$n round-trip has $c members, expected 0" }
        Write-Host "  [OK] $n round-trip: 0 members, placement kept" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== 3. Confirm End-migrated overrides untouched ===" -ForegroundColor Cyan
$endOv = @('aviary','keep_kayra','heavenly_rider','heavenly_conqueror','heavenly_challenger')
$ovDir = Join-Path $Root 'kubejs\data\dungeons_arise\worldgen\structure'
foreach ($n in $endOv) {
    $p = Join-Path $ovDir "$n.json"
    if (Test-Path -LiteralPath $p) {
        $hasEnd = (Get-Content -LiteralPath $p -Raw -Encoding UTF8) -match 'beloong:is_the_end'
        Write-Host "  $n override present, end-tag=$hasEnd"
    } else {
        Write-Host "  $n : no override" -ForegroundColor DarkYellow
    }
}

Write-Host ""
if ($script:fail.Count -gt 0) {
    Write-Host "=== FAILED: $($script:fail.Count) ===" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "[OK] all assertions passed" -ForegroundColor Green
if (-not $Apply) { Write-Host "(dry-run; no files written. Add -Apply to write.)" -ForegroundColor Yellow }
exit 0
