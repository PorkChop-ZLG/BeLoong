# prune-disaster-tags.ps1
# Remove the unused (zero-reference) beloong:disaster/* theme tags and their subfolders.
#
# Context
#   The 31 theme tags were built by mirroring NeoForge's c: taxonomy, so 10 of them live
#   in nested folders (is_hot/overworld, is_mountain/peak, is_tree/coniferous, ...).
#   Only 13 tags are actually referenced by the 33 dungeons_arise has_structure tags.
#   This script deletes the other 18, leaving a flat directory of 13 files.
#
# Safety
#   - Refuses to run if any to-be-deleted tag is still referenced anywhere under kubejs\data.
#   - Refuses to run if any retained tag is missing.
#   - Verifies the 33 DA tags still resolve afterwards.
#
# Known consequence (accepted)
#   beloong:river loses its only theme tag (is_river). Like beloong:caves, it is then
#   covered only by the master ledger beloong:is_disaster. No structure is affected.
#
# Reversibility
#   Deletion is fully reversible: restore the theme list in gen-disaster-tags.ps1 and re-run it.
#   This script ALSO updates that list so a re-run will not recreate the pruned tags.
#
# NOTE: 100% ASCII BY DESIGN.
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\prune-disaster-tags.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\prune-disaster-tags.ps1 -Apply

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TagRoot = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\disaster'
$DataDir = Join-Path $Root 'kubejs\data'
$GenScript = Join-Path $PSScriptRoot 'gen-disaster-tags.ps1'

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

# ---------------------------------------------------------------- intended sets
$Keep = @(
    'is_forest','is_plains','is_taiga','is_hill','is_snowy','is_ocean','is_beach',
    'is_desert','is_badlands','is_mountain','is_windswept','is_jungle','is_swamp'
)
$Prune = @(
    'is_hot/overworld','is_cold/overworld','is_temperate/overworld',
    'is_wet/overworld','is_dry/overworld',
    'is_dense_vegetation/overworld','is_sparse_vegetation/overworld',
    'is_mountain/peak','is_mountain/slope','is_tree/coniferous',
    'is_dead','is_floral','is_icy','is_magical','is_river','is_sandy','is_savanna','is_wasteland'
)

Write-Host ""
Write-Host "=== 1. Inventory on disk ===" -ForegroundColor Cyan
$onDisk = @(Get-ChildItem -LiteralPath $TagRoot -Recurse -File -Filter *.json |
    ForEach-Object { $_.FullName.Substring($TagRoot.Length + 1).Replace('\','/').Replace('.json','') } | Sort-Object)
Write-Host "  tags on disk: $($onDisk.Count)"
if ($onDisk.Count -ne 31) { Add-Fail "expected 31 tags on disk, found $($onDisk.Count)" }

$expectAll = @(@($Keep) + @($Prune) | Sort-Object)
$d1 = @($onDisk | Where-Object { $expectAll -notcontains $_ })
$d2 = @($expectAll | Where-Object { $onDisk -notcontains $_ })
if ($d1.Count) { Add-Fail "unexpected tags on disk: $($d1 -join ', ')" }
if ($d2.Count) { Add-Fail "expected tags missing from disk: $($d2 -join ', ')" }
if (-not $d1.Count -and -not $d2.Count) { Write-Host "  [OK] disk matches keep(13) + prune(18) = 31" -ForegroundColor Green }

Write-Host ""
Write-Host "=== 2. Safety: pruned tags must be unreferenced ===" -ForegroundColor Cyan
$refFiles = @(Get-ChildItem -LiteralPath $DataDir -Recurse -File -Filter *.json |
                Where-Object { $_.FullName -notlike "$TagRoot*" })
Write-Host "  scanning $($refFiles.Count) data files (excluding the disaster tag dir itself)"
$stillReferenced = @()
foreach ($p in $Prune) {
    $needle = "beloong:disaster/$p"
    # whole-token match so is_mountain does not match is_mountain/peak
    $re = [regex]::Escape($needle) + '(?![A-Za-z0-9_/-])'
    foreach ($f in $refFiles) {
        $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        if ($txt -match $re) { $stillReferenced += "$p <- $($f.Name)"; break }
    }
}
if ($stillReferenced.Count) {
    $stillReferenced | ForEach-Object { Add-Fail "STILL REFERENCED, refusing to delete: $_" }
} else {
    Write-Host "  [OK] all 18 pruned tags are unreferenced (whole-token match)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 3. Safety: retained tags must be present ===" -ForegroundColor Cyan
foreach ($k in $Keep) {
    if ($onDisk -notcontains $k) { Add-Fail "retained tag missing on disk: $k" }
}
if (-not $script:fail.Count) { Write-Host "  [OK] all 13 retained tags present" -ForegroundColor Green }

if ($script:fail.Count) {
    Write-Host ""
    Write-Host "ABORT: safety checks failed, nothing deleted" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

# ---------------------------------------------------------------- 4. delete
Write-Host ""
Write-Host "=== 4. Delete pruned tags ===" -ForegroundColor Cyan
if (-not $Apply) {
    foreach ($p in $Prune) { Write-Host "  would delete: $p.json" }
    Write-Host ""
    Write-Host "(dry-run; nothing deleted. Add -Apply to delete.)" -ForegroundColor Yellow
    exit 0
}

foreach ($p in $Prune) {
    $f = Join-Path $TagRoot ($p.Replace('/','\') + '.json')
    if (Test-Path -LiteralPath $f) {
        [System.IO.File]::Delete($f)
        Write-Host "  deleted: $p.json"
    }
}
# remove now-empty subfolders (deepest first)
$dirs = @(Get-ChildItem -LiteralPath $TagRoot -Directory -Recurse | Sort-Object { $_.FullName.Length } -Descending)
foreach ($dir in $dirs) {
    $left = @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File)
    if ($left.Count -eq 0) {
        [System.IO.Directory]::Delete($dir.FullName, $true)
        Write-Host "  removed empty folder: $($dir.Name)"
    }
}

# ---------------------------------------------------------------- 5. verify
Write-Host ""
Write-Host "=== 5. Post-delete verification ===" -ForegroundColor Cyan
$after = @(Get-ChildItem -LiteralPath $TagRoot -Recurse -File -Filter *.json)
Write-Host "  tags remaining: $($after.Count)"
if ($after.Count -ne 13) { Add-Fail "expected 13 tags remaining, found $($after.Count)" }
$afterDirs = @(Get-ChildItem -LiteralPath $TagRoot -Directory)
Write-Host "  subfolders remaining: $($afterDirs.Count)"
if ($afterDirs.Count -ne 0) { Add-Fail "expected 0 subfolders, found $($afterDirs.Count)" }
$afterNames = @($after | ForEach-Object { $_.BaseName } | Sort-Object)
$dk = @($Keep | Sort-Object)
$diff = @(Compare-Object $dk $afterNames)
if ($diff.Count) { Add-Fail "remaining set does not equal keep set" }
else { Write-Host "  [OK] directory is flat: exactly the 13 kept tags" -ForegroundColor Green }

# DA tags must still resolve
$daDir = Join-Path $Root 'kubejs\data\dungeons_arise\tags\worldgen\biome\has_structure'
$broken = @()
foreach ($f in (Get-ChildItem -LiteralPath $daDir -File -Filter *.json)) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    foreach ($m in [regex]::Matches($txt, '#beloong:disaster/([A-Za-z0-9_/-]+)')) {
        if ($Keep -notcontains $m.Groups[1].Value) { $broken += "$($f.BaseName) -> $($m.Groups[1].Value)" }
    }
}
if ($broken.Count) { Add-Fail "DA tags now reference deleted themes: $($broken -join ', ')" }
else { Write-Host "  [OK] all DA theme references still resolve" -ForegroundColor Green }

# ---------------------------------------------------------------- 6. sync generator
Write-Host ""
Write-Host "=== 6. Sync gen-disaster-tags.ps1 theme list ===" -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $GenScript)) { Add-Fail "generator not found: $GenScript" }
else {
    $gs = [System.IO.File]::ReadAllText($GenScript, [System.Text.Encoding]::UTF8)
    $removed = 0
    foreach ($p in $Prune) {
        # match the table line:  @{ Id='<p>'; ... }
        $re = "(?m)^[ \t]*@\{ Id='" + [regex]::Escape($p) + "';\s*Bwg=[^\r\n]*\r?\n"
        if ($gs -match $re) { $gs = [regex]::Replace($gs, $re, ''); $removed++ }
    }
    # fix the count assertion
    $gs = $gs.Replace("if (`$themes.Count -ne 31) { Add-Fail `"Expected 31 theme definitions, got `$(`$themes.Count)`" }",
                      "if (`$themes.Count -ne 13) { Add-Fail `"Expected 13 theme definitions, got `$(`$themes.Count)`" }")
    $gs = $gs.Replace('Write-Host "=== 4. Build 31 theme tags ===" -ForegroundColor Cyan',
                      'Write-Host "=== 4. Build 13 theme tags ===" -ForegroundColor Cyan')
    [System.IO.File]::WriteAllText($GenScript, $gs, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  removed $removed theme definitions from the generator table"
    if ($removed -ne 18) { Add-Fail "expected to remove 18 definitions from generator, removed $removed" }
    else { Write-Host "  [OK] generator synced (re-running it will not recreate pruned tags)" -ForegroundColor Green }
}

Write-Host ""
if ($script:fail.Count) {
    Write-Host "=== FAILED: $($script:fail.Count) ===" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "[OK] prune complete" -ForegroundColor Green
exit 0
