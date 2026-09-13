# verify-disaster-migration.ps1
# Static verification of the full DungeonsArise -> beloong:disaster migration.
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration.md (Batch 6, Task 6.1)
#
# Behaviour: READ-ONLY. Parses every produced artifact and asserts the whole design holds
#            together. Also reports theme-tag reference coverage (used vs unused).
#            Exits 1 on any error.
#
# NOTE: 100% ASCII BY DESIGN.
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\verify-disaster-migration.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModsDir = Join-Path $Root 'mods'
$BwgJar  = (Get-ChildItem -LiteralPath $ModsDir -File | Where-Object { $_.Name -like '*Biomes-Weve-Gone-NeoForge-*.jar' } | Select-Object -First 1).FullName
$CoreJar = (Get-ChildItem -LiteralPath $ModsDir -File | Where-Object { $_.Name -like 'beloong-*.jar' } | Select-Object -First 1).FullName
$DaJar   = (Get-ChildItem -LiteralPath $ModsDir -File | Where-Object { $_.Name -like '*DungeonsArise-1.21.1-*.jar' } | Select-Object -First 1).FullName

$TagRoot   = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\disaster'
$MasterTag = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\is_disaster.json'
$DaTagDir  = Join-Path $Root 'kubejs\data\dungeons_arise\tags\worldgen\biome\has_structure'
$SetDir    = Join-Path $Root 'kubejs\data\beloong\worldgen\structure_set'
$DaSetDir  = Join-Path $Root 'kubejs\data\dungeons_arise\worldgen\structure_set'

$errors = New-Object System.Collections.Generic.List[string]
$checks = 0
function Bad([string]$m) { $script:errors.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }
function OK([string]$m)  { $script:checks++; Write-Host "  [ok] $m" }

Write-Host ""
Write-Host "================ A. JSON parseability ================" -ForegroundColor Cyan
function Test-JsonDir([string]$dir, [string]$label) {
    if (-not (Test-Path -LiteralPath $dir)) { Bad "$label dir missing: $dir"; return @() }
    $fs = @(Get-ChildItem -LiteralPath $dir -Recurse -File -Filter *.json)
    $bad = 0; $objs = @()
    foreach ($f in $fs) {
        try { $objs += ,([pscustomobject]@{ Path = $f.FullName; Obj = ([System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json) }) }
        catch { $bad++; Bad "$label JSON parse failed: $($f.Name) -> $($_.Exception.Message)" }
    }
    if (-not $bad) { OK "$label : $($fs.Count) files parsed" }
    return $objs
}
$themeObjs = Test-JsonDir $TagRoot  'theme tags'
$daTagObjs = Test-JsonDir $DaTagDir 'DA structure tags'
$setObjs   = Test-JsonDir $SetDir   'beloong structure sets'
$daSetObjs = Test-JsonDir $DaSetDir 'DA cleared structure sets'

Write-Host ""
Write-Host "================ B. Biome universe ================" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($BwgJar)
$bwgBiomes = @($zip.Entries | Where-Object { $_.FullName -match '^data/biomeswevegone/worldgen/biome/[^/]+\.json$' } | ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') })
$zip.Dispose()
$zip = [System.IO.Compression.ZipFile]::OpenRead($CoreJar)
$coreBiomes = @($zip.Entries | Where-Object { $_.FullName -match '^data/beloong/worldgen/biome/[^/]+\.json$' } | ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') })
$zip.Dispose()
$validBiomes = @($bwgBiomes | ForEach-Object { "biomeswevegone:$_" }) + @($coreBiomes | ForEach-Object { "beloong:$_" })
OK "valid biome universe: $($validBiomes.Count) IDs ($($bwgBiomes.Count) BWG + $($coreBiomes.Count) core)"

$badIds = @()
foreach ($o in $themeObjs) {
    foreach ($v in @($o.Obj.values)) { if ($validBiomes -notcontains $v) { $badIds += "$($o.Path):$v" } }
}
if ($badIds.Count) { Bad "unregistered biome IDs in theme tags: $($badIds -join ', ')" }
else { OK "all theme-tag biome IDs are registered" }

Write-Host ""
Write-Host "================ C. Theme tag invariants ================" -ForegroundColor Cyan
if ($themeObjs.Count -ne 13) { Bad "theme tag count = $($themeObjs.Count), expected 13" } else { OK "theme tag count = 13 (pruned)" }
$bad = 0
foreach ($o in $themeObjs) {
    if ($o.Obj.replace -ne $false) { Bad "$($o.Path): replace must be false"; $bad++ }
    $refs = @($o.Obj.values | Where-Object { $_ -like '#*' })
    if ($refs.Count) { Bad "$($o.Path): must contain bare IDs, found refs $($refs -join ',')"; $bad++ }
    if (@($o.Obj.values).Count -eq 0) { Bad "$($o.Path): empty values"; $bad++ }
}
if (-not $bad) { OK "all 13 theme tags: replace=false, bare IDs only, non-empty" }
if (Test-Path -LiteralPath (Join-Path $TagRoot 'is_cave.json')) { Bad "is_cave.json must NOT exist (cancelled)" } else { OK "is_cave.json absent (cancelled as designed)" }
$subDirs = @(Get-ChildItem -LiteralPath $TagRoot -Directory)
if ($subDirs.Count) { Bad "theme tag dir must be flat, found $($subDirs.Count) subfolders" } else { OK "theme tag dir is flat (0 subfolders)" }

foreach ($n in @('is_ocean','is_windswept','is_hill')) {
    $p = Join-Path $TagRoot "$n.json"
    if (-not (Test-Path -LiteralPath $p)) { Bad "missing theme tag $n"; continue }
    $v = @(([System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).values)
    if (-not ($v[0] -like 'beloong:*')) { Bad "$($n): first entry is not a custom biome" } else { OK "$($n): custom biome on top" }
}

Write-Host ""
Write-Host "================ D. Master ledger ================" -ForegroundColor Cyan
$mv = @(([System.IO.File]::ReadAllText($MasterTag, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).values)
if ($mv.Count -ne 60) { Bad "is_disaster count = $($mv.Count), expected 60" } else { OK "is_disaster = 60 entries" }
$mc = @($mv | Where-Object { $_ -like 'beloong:*' }).Count
$mb = @($mv | Where-Object { $_ -like 'biomeswevegone:*' }).Count
if ($mc -ne 5) { Bad "is_disaster custom count = $mc, expected 5" } else { OK "is_disaster custom biomes = 5" }
if ($mb -ne 55) { Bad "is_disaster BWG count = $mb, expected 55" } else { OK "is_disaster BWG biomes = 55" }
if (-not ($mv[0] -like 'beloong:*')) { Bad "is_disaster: custom biomes not at top" } else { OK "is_disaster: custom biomes on top" }
$dups = @($mv | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($dups.Count) { Bad "is_disaster duplicates: $($dups -join ',')" } else { OK "is_disaster: no duplicates" }

Write-Host ""
Write-Host "================ E. DA structure tags ================" -ForegroundColor Cyan
$mine = @($daTagObjs | Where-Object { ([System.IO.File]::ReadAllText($_.Path, [System.Text.Encoding]::UTF8)) -match 'beloong:' })
if ($mine.Count -ne 33) { Bad "DA tags referencing beloong: = $($mine.Count), expected 33" } else { OK "33 DA structure tags reference beloong:" }

$themeNames = @(Get-ChildItem -LiteralPath $TagRoot -Recurse -File | ForEach-Object { $_.FullName.Substring($TagRoot.Length + 1).Replace('\','/').Replace('.json','') })
$badRef = @(); $usedThemes = @()
foreach ($o in $mine) {
    $v = @($o.Obj.values)
    if ($o.Obj.replace -ne $true) { Bad "$($o.Path): replace must be true" }
    foreach ($r in $v) {
        if ($r -eq '#beloong:is_disaster') { continue }
        $m = [regex]::Match($r, '^#beloong:disaster/(.+)$')
        if (-not $m.Success) { $badRef += "$($o.Path):$r"; continue }
        $usedThemes += $m.Groups[1].Value
        if ($themeNames -notcontains $m.Groups[1].Value) { $badRef += "$($o.Path):$r (no file)" }
    }
}
if ($badRef.Count) { Bad "unresolvable theme refs: $($badRef -join ', ')" } else { OK "all DA theme refs resolve to existing theme tags" }

foreach ($n in @('foundry','mining_complex','plague_asylum','infested_temple')) {
    $p = Join-Path $DaTagDir "${n}_biomes.json"
    if (-not (Test-Path -LiteralPath $p)) { Bad "missing underground tag: $n"; continue }
    $v = @(([System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).values)
    if ($v.Count -ne 1 -or $v[0] -ne '#beloong:is_disaster') { Bad "$($n) must reference only #beloong:is_disaster, got $($v -join ',')" }
}
OK "4 underground structures reference the master ledger"

foreach ($n in @('heavenly_rider','heavenly_conqueror','heavenly_challenger','mining_system','giant_mushroom','small_prairie_house')) {
    $p = Join-Path $DaTagDir "${n}_biomes.json"
    if (Test-Path -LiteralPath $p) {
        if (([System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)) -match 'beloong:disaster|beloong:is_disaster') { Bad "$($n) was modified but should not be" }
    }
}
OK "excluded structures (End/heavenly/mining_system/deleted) not re-pointed at disaster themes"

Write-Host ""
Write-Host "================ F. Structure sets ================" -ForegroundColor Cyan
$gp = Join-Path $SetDir 'disaster_ground_set.json'
$up = Join-Path $SetDir 'disaster_underground_set.json'
foreach ($p in @($gp, $up)) { if (-not (Test-Path -LiteralPath $p)) { Bad "missing set: $p" } }

$gj = [System.IO.File]::ReadAllText($gp, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$uj = [System.IO.File]::ReadAllText($up, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$gN = @($gj.structures).Count; $uN = @($uj.structures).Count
if ($gN -ne 29) { Bad "ground members = $gN, expected 29" } else { OK "ground = 29 members" }
if ($uN -ne 4)  { Bad "underground members = $uN, expected 4" } else { OK "underground = 4 members" }
if ($gN + $uN -ne 33) { Bad "total = $($gN + $uN), expected 33" } else { OK "total = 33 members" }

$w = @($gj.structures | ForEach-Object { $_.weight } | Group-Object | Sort-Object Name)
$wtxt = ($w | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ' '
if ($wtxt -ne '1:16 2:13') { Bad "ground weight breakdown = $wtxt, expected 1:16 2:13" } else { OK "ground weights 1:16 2:13 (large=1, small=2)" }

# Salts are the user-approved FINAL values: each is the ORIGINAL DA set's salt + 1
# (major 88371663 -> 88371664, minor 342415935 -> 342415936), keeping them traceable
# to the originals while staying unique across all 103 structure sets in the pack.
# The ground and underground sets share spacing/separation (32/16) and are told apart
# ONLY by salt, so these two assertions are the thing that keeps them distinct.
if ($gj.placement.spacing -ne 32 -or $gj.placement.separation -ne 16 -or $gj.placement.salt -ne 88371664) { Bad "ground placement wrong (salt=$($gj.placement.salt), expected 88371664)" } else { OK "ground placement 32/16/88371664" }
if ($uj.placement.spacing -ne 32 -or $uj.placement.separation -ne 16 -or $uj.placement.salt -ne 342415936) { Bad "underground placement wrong (salt=$($uj.placement.salt), expected 342415936)" } else { OK "underground placement 32/16/342415936" }
if ($gj.placement.exclusion_zone) { Bad "ground set must NOT declare an exclusion_zone" } else { OK "ground set has no exclusion_zone" }
if ($uj.placement.exclusion_zone) { Bad "underground set must NOT declare an exclusion_zone" } else { OK "underground set has no exclusion_zone" }

# Spawn exclusion (user-approved 250 blocks). Two silent-failure modes are guarded:
#   a) the Moogs type is reverted to minecraft:random_spread -> the unknown key survives
#      parsing but is ignored, so the guard vanishes with no error anywhere;
#   b) min_distance_from_world_origin is dropped -> same silent loss.
# The value is in BLOCKS (the reference impl multiplies chunk coords by 16), and the
# origin it checks is dimension-local, not the overworld's.
$MoogsType = 'moogs_structures:advanced_random_spread'
if ($gj.placement.type -ne $MoogsType) { Bad "ground placement type = '$($gj.placement.type)', expected '$MoogsType'" } else { OK "ground placement type is the spawn-excluding one" }
if ($gj.placement.min_distance_from_world_origin -ne 250) { Bad "ground min_distance_from_world_origin = '$($gj.placement.min_distance_from_world_origin)', expected 250" } else { OK "ground keeps DA structures >= 250 blocks from the origin" }
if ($uj.placement.type -ne 'minecraft:random_spread') { Bad "underground placement type must stay vanilla random_spread" } else { OK "underground placement type unchanged (vanilla)" }
if ($null -ne $uj.placement.min_distance_from_world_origin) { Bad "underground must NOT declare min_distance_from_world_origin" } else { OK "underground declares no origin guard" }

# Regression: a MUTUAL exclusion pair causes unbounded recursion in vanilla's
# StructurePlacement.ExclusionZone and a StackOverflowError on a worldgen worker thread.
$refs = @{}
$dataRoot = (Resolve-Path -LiteralPath (Join-Path $Root 'kubejs\data')).Path
foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $Root 'kubejs\data') -Recurse -File -Filter *.json)) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($txt, '"other_set"\s*:\s*"([^"]+)"')
    if ($m.Success) {
        $ns = ($f.FullName.Substring($dataRoot.Length + 1) -split '\\')[0]
        $refs[($ns + ':' + $f.BaseName)] = $m.Groups[1].Value
    }
}
$cycles = @()
foreach ($k in $refs.Keys) { $v = $refs[$k]; if ($refs.ContainsKey($v) -and $refs[$v] -eq $k) { $cycles += "$k <-> $v" } }
if ($cycles.Count) { Bad "mutual exclusion cycle(s) present: $($cycles -join ' ; ')" }
else { OK "no mutual exclusion pair among $($refs.Count) exclusion_zone references" }

$zip = [System.IO.Compression.ZipFile]::OpenRead($DaJar)
$jarIds = @($zip.Entries | Where-Object { $_.FullName -match '^data/dungeons_arise/worldgen/structure/[^/]+\.json$' } | ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') })
$zip.Dispose()
$badIds = @(); $banned = @('giant_mushroom','mining_system','small_prairie_house','aviary','keep_kayra','heavenly_rider','heavenly_conqueror','heavenly_challenger')
foreach ($e in (@($gj.structures) + @($uj.structures))) {
    $id = $e.structure.Replace('dungeons_arise:','')
    if ($jarIds -notcontains $id) { $badIds += "$id (not in jar)" }
    if ($banned -contains $id)    { $badIds += "$id (should be excluded)" }
}
if ($badIds.Count) { Bad "bad set members: $($badIds -join ', ')" } else { OK "all 33 set members valid and none excluded" }

foreach ($n in @('major_structures','minor_structures')) {
    $p = Join-Path $DaSetDir "$n.json"
    if (-not (Test-Path -LiteralPath $p)) { Bad "cleared set missing: $n" } else {
        $o = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if (@($o.structures).Count -ne 0) { Bad "$n not emptied" } else { OK "$n emptied, placement kept (spacing=$($o.placement.spacing))" }
    }
}

Write-Host ""
Write-Host "================ G. Theme reference coverage (informational) ================" -ForegroundColor Cyan
$usedUnique = @($usedThemes | Sort-Object -Unique)
$unused = @($themeNames | Where-Object { $usedUnique -notcontains $_ } | Sort-Object)
Write-Host "  theme tags total     : $($themeNames.Count)"
Write-Host "  referenced by DA tags: $($usedUnique.Count)"
Write-Host "  NOT referenced       : $($unused.Count)"
if ($unused.Count) { $unused | ForEach-Object { Write-Host "      $_" } }
$masterRefCount = @($mine | Where-Object { @($_.Obj.values) -contains '#beloong:is_disaster' }).Count
Write-Host "  tags using #beloong:is_disaster (master ledger): $masterRefCount"

Write-Host ""
Write-Host "================ SUMMARY ================" -ForegroundColor Cyan
Write-Host "  checks passed : $checks"
Write-Host "  errors        : $($errors.Count)"
if ($errors.Count) {
    Write-Host ""
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "[FAIL] static verification FAILED" -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "[PASS] static verification passed" -ForegroundColor Green
exit 0
