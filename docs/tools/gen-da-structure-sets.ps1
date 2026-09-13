# gen-da-structure-sets.ps1
# Create beloong:disaster_ground_set and beloong:disaster_underground_set.
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md section 2.7
#
# Params (approved):
#   ground      : spacing 32, separation 16, salt 20260921
#                 placement moogs_structures:advanced_random_spread + min_distance_from_world_origin 250
#   underground : spacing 32, separation 16, salt 20260922, placement minecraft:random_spread (untouched)
#
# Spawn exclusion (see the long comment further down for the full derivation):
#   The ground set is the ONLY set in the pack that keeps DA structures away from the
#   dimension origin. Vanilla 1.21.1 cannot express this - StructurePlacementType has
#   exactly two entries (random_spread, concentric_rings) and neither looks at the origin.
#   moogs_structures:advanced_random_spread (MoogsStructureLib, already a dependency of
#   three structure mods in this pack) adds min_distance_from_world_origin, in BLOCKS.
#   The origin it checks is DIMENSION-LOCAL, not the overworld's.
#
# NO exclusion_zone - deliberately omitted.
#   The disaster dimension's structures are already designed not to overlap. More importantly,
#   a MUTUAL exclusion pair (A excludes B and B excludes A) causes unbounded recursion in
#   vanilla's StructurePlacement.ExclusionZone and blows the worldgen worker thread's stack:
#     StackOverflowError
#       StructurePlacement.isStructureChunk(:89)
#       -> applyInteractionsWithOtherStructures(:93)
#       -> ExclusionZone.isPlacementForbidden(:144)
#       -> ChunkGeneratorStructureState.hasStructureChunkInRange(:198)
#       -> isStructureChunk(:89)  ... 255 levels deep
#   Observed in logs/debug-2.log.gz as "Worker-Main-17 ... StackOverflowError".
#   A later assertion in this script scans the whole pack and refuses to proceed if ANY
#   mutual exclusion pair exists.
#
# Weights (user-approved): LARGE = 1, SMALL = 2.
#   Derivation (from the ORIGINAL DA structure sets, see section 2):
#     major_structures weight 1   -> large -> 1
#     major_structures weight 2/3 -> small -> 2
#     minor_structures (all)      -> small -> 2
#   Result: ground 16 large + 13 small ; underground all 4 small.
#
# NOTE: 100% ASCII BY DESIGN.
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-da-structure-sets.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-da-structure-sets.ps1 -Apply

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
$OutDir  = Join-Path $Root 'kubejs\data\beloong\worldgen\structure_set'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$MoogsLib = (Get-ChildItem -LiteralPath $ModsDir -File |
              Where-Object { $_.Name -like '*MoogsStructureLib*.jar' } |
              Select-Object -First 1).FullName

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

if (-not $DaJar) { throw 'DungeonsArise jar not found under mods' }
if (-not $MoogsLib) { throw 'MoogsStructureLib jar not found under mods (required by the ground placement type)' }

$EndMigrated = @('aviary','keep_kayra','heavenly_rider','heavenly_conqueror','heavenly_challenger')
$Deleted     = @('giant_mushroom','mining_system','small_prairie_house')
$Underground = @('foundry','mining_complex','plague_asylum','infested_temple')
# NOTE: weights are NOT hardcoded - they are derived from the original DA structure sets
#       in section 2 below (major weight 1 = large = 1; everything else = small = 2).

# --- Spawn exclusion (user-approved: 250 blocks) ---------------------------------
# The GROUND set uses moogs_structures:advanced_random_spread instead of the vanilla
# random_spread, because that type is the only one available in this pack that can
# exclude a radius around the world origin. Vanilla 1.21.1 registers exactly two
# placement types (random_spread, concentric_rings) and neither knows about the origin.
#
# UNIT IS BLOCKS, NOT CHUNKS. The reference implementation (Repurposed Structures /
# Dragon Survival AdvancedRandomSpread.isPlacementChunk) does:
#     xBlockPos = x * 16 ; zBlockPos = z * 16
#     if (xBlockPos^2 + zBlockPos^2 < minDistance^2) return false;
# so the excluded region is a CIRCLE of radius MinDistanceFromWorldOrigin blocks.
# 250 blocks = 15.6 chunks: "no DA ground structure within ~16 chunks of the origin".
$MinDistanceFromWorldOrigin = 250
$MoogsReducedType = 'moogs_structures:advanced_random_spread'

# The origin is DIMENSION-LOCAL. The Moogs class references no cross-dimension type at
# all (no Level / ServerLevel / Overworld / getSharedSpawnPos); it only ever sees the
# per-dimension ChunkGeneratorStructureState and the chunk coords handed to
# isPlacementChunk. ChunkGeneratorStructureState is built per dimension (createForNormal
# receives that dimension's BiomeSource), so (0,0) means THIS dimension's origin.
# For beloong:disaster that is also 1:1 with the overworld: its dimension_type declares
# coordinate_scale 1.0 and DisasterPortalBlock maps downward travel 1:1.
#
# The UNDERGROUND set deliberately keeps vanilla random_spread: the user asked for the
# ground set only, and this keeps exactly one variable changed.

# --- Guard: verify the Moogs library actually registers the placement type we depend on,
#     and that the field name we write matches its codec. Reads the class constant pool.
$zipM = [System.IO.Compression.ZipFile]::OpenRead($MoogsLib)
$msEntry = $zipM.Entries | Where-Object { $_.FullName -eq 'com/finndog/moogs_structures/world/structures/placements/AdvancedRandomSpread.class' } | Select-Object -First 1
if (-not $msEntry) {
    $zipM.Dispose()
    throw 'MoogsStructureLib does not contain AdvancedRandomSpread.class - placement type unavailable'
}
$msStream = $msEntry.Open()
$msBytes = New-Object byte[] $msEntry.Length
[void]$msStream.Read($msBytes, 0, $msBytes.Length)
$msStream.Close()
$zipM.Dispose()
$msText = [System.Text.Encoding]::ASCII.GetString($msBytes)
if ($msText -notmatch 'min_distance_from_world_origin') {
    throw 'AdvancedRandomSpread.class has no min_distance_from_world_origin field - refusing to emit a silently ignored key'
}
if ($msText -match 'ServerLevel|getSharedSpawnPos|net/minecraft/server/level') {
    throw 'AdvancedRandomSpread references server-level/overworld types - origin semantics must be re-derived'
}
Write-Host "  Moogs placement type verified: min_distance_from_world_origin present, no cross-dimension refs"

Write-Host ""
Write-Host "=== 1. Derive members from jar ===" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($DaJar)
$all = @($zip.Entries |
    Where-Object { $_.FullName -match '^data/dungeons_arise/worldgen/structure/[^/]+\.json$' } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') } |
    Sort-Object)
$zip.Dispose()

$ground = @($all | Where-Object { $EndMigrated -notcontains $_ -and $Deleted -notcontains $_ -and $Underground -notcontains $_ } | Sort-Object)
Write-Host "  ground      : $($ground.Count)"
Write-Host "  underground : $($Underground.Count)"
if ($ground.Count -ne 29) { Add-Fail "expected 29 ground, got $($ground.Count)" }
if ($Underground.Count -ne 4) { Add-Fail "expected 4 underground, got $($Underground.Count)" }

Write-Host ""
Write-Host "=== 2. Derive weights from the ORIGINAL DA structure sets ===" -ForegroundColor Cyan
# Weight rule (user-approved):
#   original major_structures: weight 1 = LARGE -> 1 ; weight 2 or 3 = small -> 2
#   original minor_structures: every member is a small structure -> 2
# Derived from the jar so it can never drift from the original data.
$origSet = @{}
$origW   = @{}
$zip2 = [System.IO.Compression.ZipFile]::OpenRead($DaJar)
foreach ($sn in @('major_structures','minor_structures')) {
    $se = $zip2.Entries | Where-Object { $_.FullName -eq "data/dungeons_arise/worldgen/structure_set/$sn.json" } | Select-Object -First 1
    if (-not $se) { Add-Fail "original set not found in jar: $sn"; continue }
    $sr = New-Object System.IO.StreamReader($se.Open()); $st = $sr.ReadToEnd(); $sr.Close()
    $sj = $st | ConvertFrom-Json
    foreach ($s in $sj.structures) {
        $k = $s.structure.Replace('dungeons_arise:','')
        $origSet[$k] = $sn
        $origW[$k]   = $s.weight
    }
}
$zip2.Dispose()
Write-Host "  original sets loaded: major+minor, $($origSet.Count) structures"

$script:OrigSet = $origSet
$script:OrigW   = $origW
function Get-Weight([string]$s) {
    if (-not $script:OrigSet.ContainsKey($s)) { Add-Fail "no original weight for '$s' (not in major/minor sets)"; return 2 }
    if ($script:OrigSet[$s] -eq 'minor_structures') { return 2 }   # minor = all small
    if ($script:OrigW[$s] -eq 1) { return 1 }                      # major weight 1 = large
    return 2                                                       # major weight 2/3 = small
}

$members = @($ground) + @($Underground)
$g1 = @($ground | Where-Object { (Get-Weight $_) -eq 1 }).Count
$g2 = @($ground | Where-Object { (Get-Weight $_) -eq 2 }).Count
Write-Host "  ground breakdown: w1=$g1 w2=$g2 (sum $($g1+$g2))"
if (($g1 + $g2) -ne 29) { Add-Fail "ground weight breakdown sums to $($g1+$g2), expected 29" }
if ($g1 -ne 16 -or $g2 -ne 13) { Add-Fail "ground weights should be 16/13, got $g1/$g2" }
# Underground: all four come from major_structures with original weight 1, so the same
# rule classifies them as LARGE -> weight 1. Matches the already-deployed set.
$u1 = @($Underground | Where-Object { (Get-Weight $_) -eq 1 }).Count
$u2 = @($Underground | Where-Object { (Get-Weight $_) -eq 2 }).Count
Write-Host "  underground breakdown: w1=$u1 w2=$u2"
if (($u1 + $u2) -ne 4) { Add-Fail "underground weight breakdown sums to $($u1+$u2), expected 4" }

function New-SetJson([object[]]$entries, [int]$spacing, [int]$separation, [long]$salt,
                     [string]$placementType = 'minecraft:random_spread',
                     [int]$minDistanceFromWorldOrigin = 0) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("{`r`n")
    [void]$sb.Append("  `"placement`": {`r`n")
    [void]$sb.Append("    `"type`": `"$placementType`",`r`n")
    [void]$sb.Append("    `"spacing`": $spacing,`r`n")
    [void]$sb.Append("    `"separation`": $separation,`r`n")
    [void]$sb.Append("    `"salt`": $salt")
    if ($minDistanceFromWorldOrigin -gt 0) {
        [void]$sb.Append(",`r`n")
        [void]$sb.Append("    `"min_distance_from_world_origin`": $minDistanceFromWorldOrigin`r`n")
    } else {
        [void]$sb.Append("`r`n")
    }
    [void]$sb.Append("  },`r`n")
    [void]$sb.Append("  `"structures`": [`r`n")
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $e = $entries[$i]
        $comma = if ($i -lt $entries.Count - 1) { ',' } else { '' }
        [void]$sb.Append("    { `"structure`": `"dungeons_arise:$($e.Name)`", `"weight`": $($e.Weight) }$comma`r`n")
    }
    [void]$sb.Append("  ]`r`n")
    [void]$sb.Append("}`r`n")
    return $sb.ToString()
}

$groundEntries = @($ground | ForEach-Object { [pscustomobject]@{ Name = $_; Weight = (Get-Weight $_) } })
$underEntries  = @($Underground | ForEach-Object { [pscustomobject]@{ Name = $_; Weight = (Get-Weight $_) } })

# Ground: spawn-excluding placement. Underground: untouched vanilla placement.
$groundJson = New-SetJson $groundEntries 32 16 20260921 $MoogsReducedType $MinDistanceFromWorldOrigin
$underJson  = New-SetJson $underEntries  32 16 20260922

Write-Host ""
Write-Host "=== 3. Emit structure sets ===" -ForegroundColor Cyan
Write-Host "  ground placement     : $MoogsReducedType / min_distance_from_world_origin=$MinDistanceFromWorldOrigin blocks"
Write-Host "  underground placement: minecraft:random_spread (unchanged)"
if ($Apply) {
    if (-not [System.IO.Directory]::Exists($OutDir)) { [System.IO.Directory]::CreateDirectory($OutDir) | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path $OutDir 'disaster_ground_set.json'), $groundJson, $Utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $OutDir 'disaster_underground_set.json'), $underJson, $Utf8NoBom)
    Write-Host "  written: disaster_ground_set.json ($($groundEntries.Count) entries)" -ForegroundColor Green
    Write-Host "  written: disaster_underground_set.json ($($underEntries.Count) entries)" -ForegroundColor Green

    $gj = Get-Content -LiteralPath (Join-Path $OutDir 'disaster_ground_set.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $uj = Get-Content -LiteralPath (Join-Path $OutDir 'disaster_underground_set.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($gj.structures).Count -ne 29) { Add-Fail "ground round-trip = $(@($gj.structures).Count), expected 29" }
    if (@($uj.structures).Count -ne 4)  { Add-Fail "underground round-trip = $(@($uj.structures).Count), expected 4" }
    if ($gj.placement.spacing -ne 32 -or $gj.placement.separation -ne 16) { Add-Fail "ground placement wrong" }
    if ($uj.placement.spacing -ne 32 -or $uj.placement.separation -ne 16) { Add-Fail "underground placement wrong" }
    if ($gj.placement.exclusion_zone) { Add-Fail "ground must NOT have an exclusion_zone" }
    if ($uj.placement.exclusion_zone) { Add-Fail "underground must NOT have an exclusion_zone" }
    # Spawn exclusion must be present on the ground set and absent from the underground set.
    if ($gj.placement.type -ne $MoogsReducedType) { Add-Fail "ground placement type is '$($gj.placement.type)', expected '$MoogsReducedType'" }
    if ($gj.placement.min_distance_from_world_origin -ne $MinDistanceFromWorldOrigin) {
        Add-Fail "ground min_distance_from_world_origin is '$($gj.placement.min_distance_from_world_origin)', expected $MinDistanceFromWorldOrigin"
    }
    if ($uj.placement.type -ne 'minecraft:random_spread') { Add-Fail "underground placement type must stay 'minecraft:random_spread'" }
    if ($null -ne $uj.placement.min_distance_from_world_origin) { Add-Fail "underground must NOT declare min_distance_from_world_origin" }
    Write-Host "  [OK] round-trip verified (spawn exclusion on ground only, no exclusion_zone)" -ForegroundColor Green
}

# ---------------------------------------------------------------- 4. regression: no mutual exclusion pairs anywhere
Write-Host ""
Write-Host "=== 4. Regression: scan pack for mutual exclusion cycles ===" -ForegroundColor Cyan
$DataDir = Join-Path $Root 'kubejs\data'
$refs = @{}
$dataRoot = (Resolve-Path -LiteralPath $DataDir).Path
foreach ($f in (Get-ChildItem -LiteralPath $DataDir -Recurse -File -Filter *.json)) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($txt, '"other_set"\s*:\s*"([^"]+)"')
    if ($m.Success) {
        $ns  = ($f.FullName.Substring($dataRoot.Length + 1) -split '\\')[0]
        $refs[($ns + ':' + $f.BaseName)] = $m.Groups[1].Value
    }
}
Write-Host "  exclusion_zone references found: $($refs.Count)"
$cycles = @()
foreach ($k in $refs.Keys) {
    $v = $refs[$k]
    if ($refs.ContainsKey($v) -and $refs[$v] -eq $k) { $cycles += "$k <-> $v" }
}
if ($cycles.Count) {
    Add-Fail "mutual exclusion cycle(s) would cause StackOverflowError: $($cycles -join ' ; ')"
} else {
    Write-Host "  [OK] no mutual exclusion pair (all references are one-way)" -ForegroundColor Green
}

# ---------------------------------------------------------------- 5. regression: the ground set keeps its origin guard
# Two ways this silently breaks, both guarded here:
#   a) the type is reverted to minecraft:random_spread -> vanilla silently keeps the
#      unknown key in the parsed map but ignores it, so the guard vanishes with no error;
#   b) min_distance_from_world_origin is dropped -> same silent loss.
# NOTE: we deliberately do NOT require every moogs placement in the pack to declare a
# guard. mvs's three nether sets use the type without one on purpose (a nether origin
# guard is meaningless), and that is a legitimate use of the field being Optional.
Write-Host ""
Write-Host "=== 5. Regression: disaster_ground_set keeps its origin guard ===" -ForegroundColor Cyan
$groundSetPath = Join-Path $OutDir 'disaster_ground_set.json'
$groundRaw = [System.IO.File]::ReadAllText($groundSetPath, [System.Text.Encoding]::UTF8)
$groundObj = $groundRaw | ConvertFrom-Json
if ($groundObj.placement.type -ne $MoogsReducedType) {
    Add-Fail "disaster_ground_set placement type is '$($groundObj.placement.type)', expected '$MoogsReducedType'"
}
if ($groundObj.placement.min_distance_from_world_origin -ne $MinDistanceFromWorldOrigin) {
    Add-Fail "disaster_ground_set min_distance_from_world_origin is '$($groundObj.placement.min_distance_from_world_origin)', expected $MinDistanceFromWorldOrigin"
}
if ($groundObj.placement.spacing -ne 32 -or $groundObj.placement.separation -ne 16 -or $groundObj.placement.salt -ne 20260921) {
    Add-Fail "disaster_ground_set placement spacing/separation/salt changed"
}
# Informational: how many sets in the pack actually use the origin guard.
$guardCount = 0
foreach ($f in (Get-ChildItem -LiteralPath $DataDir -Recurse -File -Filter *.json)) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($txt -match '"min_distance_from_world_origin"\s*:\s*\d+') { $guardCount++ }
}
Write-Host "  sets declaring min_distance_from_world_origin: $guardCount"
$gp = $groundObj.placement
Write-Host "  ground guard: type=$($gp.type) min=$($gp.min_distance_from_world_origin) spacing=$($gp.spacing) separation=$($gp.separation) salt=$($gp.salt)"
Write-Host "  [OK] ground origin guard present" -ForegroundColor Green

# MoogsStructureLib also has its own config (config/moogs_structures.json) that can scale
# spacing or disable structures outright. A universal multiplier != 1.0 would silently
# rescale our spacing, and a disabled entry would remove the set entirely. The multipliers
# are keyed by MOD ID / STRUCTURE ID (never by structure set), so beloong is only affected
# through the universal key - which is exactly what we check here.
Write-Host ""
Write-Host "=== 6. Regression: Moogs config must not rescale or disable our structures ===" -ForegroundColor Cyan
$msCfg = Join-Path $Root 'config\moogs_structures.json'
if (-not (Test-Path -LiteralPath $msCfg)) {
    Write-Host "  no moogs config file (defaults are neutral) - OK" -ForegroundColor Green
} else {
    $cfg = [System.IO.File]::ReadAllText($msCfg, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $uni = $cfg.spacing.universal_multiplier
    Write-Host "  universal_multiplier = $uni"
    if ($null -eq $uni) { Add-Fail "moogs config has no spacing.universal_multiplier" }
    elseif ([double]$uni -ne 1.0) { Add-Fail "moogs universal_multiplier is $uni, expected 1.0 (our spacing would be rescaled)" }
    $dis = @($cfg.disabled_structures)
    Write-Host "  disabled_structures  = $($dis.Count) entries"
    foreach ($d in $dis) {
        if ("$d" -match 'dungeons_arise|^beloong') { Add-Fail "moogs config disables '$d' - our migration would be silently voided" }
    }
    if ($script:fail.Count -eq 0) { Write-Host "  [OK] moogs config is neutral for this migration" -ForegroundColor Green }
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
