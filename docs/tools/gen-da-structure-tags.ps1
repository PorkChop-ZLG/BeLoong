# gen-da-structure-tags.ps1
# Overwrite dungeons_arise has_structure/*_biomes tags to point at beloong:disaster/* themes.
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md section 2.5
#
# Approach (approved):
#   - Overwrite the MOD'S OWN has_structure tags (replace:true). Never touch the structure
#     JSON "biomes" field: the tag is the mod's abstraction boundary.
#   - A structure's tag may reference MULTIPLE themes (values array holds several refs).
#   - The 4 underground structures point at the master ledger #beloong:is_disaster.
#
# Safety: the member set is DERIVED from the jar. The theme table below is validated
#         against it, so any typo shows up as a missing/extra key instead of silently
#         producing a wrong tag.
#
# NOTE: 100% ASCII BY DESIGN (see gen-disaster-tags.ps1 header for rationale).
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-da-structure-tags.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-da-structure-tags.ps1 -Apply

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
$OutDir    = Join-Path $Root 'kubejs\data\dungeons_arise\tags\worldgen\biome\has_structure'
$TagRoot   = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\disaster'
$MasterTag = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\is_disaster.json'
$Manifest  = Join-Path $Root 'docs\tools\out\da-structure-tags-manifest.txt'

if (-not $DaJar) { throw 'DungeonsArise jar not found under mods' }

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

# ---------------------------------------------------------------- excluded sets
$EndMigrated = @('aviary','keep_kayra','heavenly_rider','heavenly_conqueror','heavenly_challenger')
$Deleted     = @('giant_mushroom','mining_system','small_prairie_house')
$Underground = @('foundry','mining_complex','plague_asylum','infested_temple')

# ---------------------------------------------------------------- theme table (design section 2.5)
$themes = @{
    'greenwood_pub'       = @('is_forest')
    'mushroom_house'      = @('is_forest')
    'mushroom_mines'      = @('is_forest')
    'mushroom_village'    = @('is_forest')
    'thornborn_towers'    = @('is_forest')
    'mechanical_nest'     = @('is_forest','is_swamp')
    'coliseum'            = @('is_plains')
    'illager_campsite'    = @('is_plains','is_hill')
    'illager_windmill'    = @('is_plains')
    'merchant_campsite'   = @('is_plains')
    'wishing_well'        = @('is_plains')
    'abandoned_temple'    = @('is_taiga','is_hill')
    'illager_fort'        = @('is_taiga','is_snowy')
    'monastery'           = @('is_taiga','is_mountain','is_hill')
    'bathhouse'           = @('is_taiga','is_plains','is_snowy')
    'illager_corsair'     = @('is_ocean')
    'illager_galley'      = @('is_ocean','is_beach')
    'typhon'              = @('is_ocean')
    'undead_pirate_ship'  = @('is_ocean')
    'fishing_hut'         = @('is_beach')
    'lighthouse'          = @('is_beach','is_plains')
    'ceryneian_hind'      = @('is_desert')
    'scorched_mines'      = @('is_desert')
    'shiraz_palace'       = @('is_desert')
    'bandit_towers'       = @('is_badlands')
    'bandit_village'      = @('is_badlands')
    'kisegi_sanctuary'    = @('is_mountain','is_hill')
    'small_blimp'         = @('is_windswept')
    'jungle_tree_house'   = @('is_jungle')
    'foundry'             = @('@master')
    'mining_complex'      = @('@master')
    'plague_asylum'       = @('@master')
    'infested_temple'     = @('@master')
}

# ---------------------------------------------------------------- 1. derive members from jar
Write-Host ""
Write-Host "=== 1. Derive structure set from jar ===" -ForegroundColor Cyan
Write-Host "  jar: $DaJar"
$zip = [System.IO.Compression.ZipFile]::OpenRead($DaJar)
$all = @($zip.Entries |
    Where-Object { $_.FullName -match '^data/dungeons_arise/worldgen/structure/[^/]+\.json$' } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') } |
    Sort-Object)
$zip.Dispose()
Write-Host "  structures in jar : $($all.Count)"
if ($all.Count -ne 40) { Add-Fail "expected 40 structures, got $($all.Count)" }

$ground = @($all | Where-Object { $EndMigrated -notcontains $_ -and $Deleted -notcontains $_ -and $Underground -notcontains $_ })
Write-Host "  ground            : $($ground.Count)"
Write-Host "  underground       : $($Underground.Count)"
Write-Host "  migrated total    : $($ground.Count + $Underground.Count)"
if ($ground.Count -ne 29) { Add-Fail "expected 29 ground structures, got $($ground.Count)" }
if (($ground.Count + $Underground.Count) -ne 33) { Add-Fail "expected 33 migrated total, got $($ground.Count + $Underground.Count)" }

$expectedGround = @(
    'abandoned_temple','bandit_towers','bandit_village','bathhouse','ceryneian_hind','coliseum',
    'fishing_hut','greenwood_pub','illager_campsite','illager_corsair','illager_fort','illager_galley',
    'illager_windmill','jungle_tree_house','kisegi_sanctuary','lighthouse','mechanical_nest',
    'merchant_campsite','monastery','mushroom_house','mushroom_mines','mushroom_village',
    'scorched_mines','shiraz_palace','small_blimp','thornborn_towers','typhon','undead_pirate_ship',
    'wishing_well'
)
$dg1 = @($ground | Where-Object { $expectedGround -notcontains $_ })
$dg2 = @($expectedGround | Where-Object { $ground -notcontains $_ })
if ($dg1.Count -or $dg2.Count) { Add-Fail "ground set mismatch vs design: derived-only [$($dg1 -join ',')] expected-only [$($dg2 -join ',')]" }
else { Write-Host "  [OK] ground set matches design section 2.5" -ForegroundColor Green }

# ---------------------------------------------------------------- 2. validate theme table
Write-Host ""
Write-Host "=== 2. Validate theme table ===" -ForegroundColor Cyan
$members = @($ground) + @($Underground)
$t1 = @($themes.Keys | Where-Object { $members -notcontains $_ })
$t2 = @($members | Where-Object { -not $themes.ContainsKey($_) })
if ($t1.Count) { Add-Fail "theme table has extra keys: $($t1 -join ', ')" }
if ($t2.Count) { Add-Fail "theme table missing keys: $($t2 -join ', ')" }
if (-not $t1.Count -and -not $t2.Count) { Write-Host "  [OK] theme table covers exactly $($members.Count) structures" -ForegroundColor Green }

# ---------------------------------------------------------------- 3. validate theme tag files
Write-Host ""
Write-Host "=== 3. Validate theme tag files exist ===" -ForegroundColor Cyan
$haveTags = @(Get-ChildItem -LiteralPath $TagRoot -Recurse -File |
                ForEach-Object { $_.FullName.Substring($TagRoot.Length + 1).Replace('\','/').Replace('.json','') })
Write-Host "  theme tags on disk: $($haveTags.Count)"
foreach ($k in ($themes.Keys | Sort-Object)) {
    foreach ($tn in $themes[$k]) {
        if ($tn -eq '@master') {
            if (-not (Test-Path -LiteralPath $MasterTag)) { Add-Fail "$k references @master but is_disaster.json missing" }
            continue
        }
        if ($haveTags -notcontains $tn) { Add-Fail "$k references theme '$tn' which has no file" }
    }
}
if ($haveTags.Count -ne 31) { Add-Fail "expected 31 theme tags on disk, got $($haveTags.Count)" }
else { Write-Host "  [OK] 31 theme tags on disk, all references resolvable" -ForegroundColor Green }

# ---------------------------------------------------------------- 4. emit
Write-Host ""
Write-Host "=== 4. Emit has_structure tag overrides ===" -ForegroundColor Cyan
$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("# dungeons_arise has_structure/*_biomes overrides")
$manifestLines.Add("# AUTO-GENERATED. Design ref: design.md section 2.5")
$manifestLines.Add("")

$written = 0
foreach ($k in ($themes.Keys | Sort-Object)) {
    $refs = @($themes[$k] | ForEach-Object { if ($_ -eq '@master') { '#beloong:is_disaster' } else { "#beloong:disaster/$_" } })

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('{')
    $lines.Add('  "replace": true,')
    $lines.Add('  "values": [')
    for ($i = 0; $i -lt $refs.Count; $i++) {
        $comma = if ($i -lt $refs.Count - 1) { ',' } else { '' }
        $lines.Add("    `"$($refs[$i])`"$comma")
    }
    $lines.Add('  ]')
    $lines.Add('}')
    $json = ($lines -join "`r`n") + "`r`n"

    $outPath = Join-Path $OutDir "${k}_biomes.json"
    if ($Apply) {
        [System.IO.File]::WriteAllText($outPath, $json, $Utf8NoBom)
        $written++
    }
    $manifestLines.Add(("{0}_biomes`t{1}" -f $k, ($refs -join ' ')))
    if ($refs.Count -gt 1) { Write-Host ("  {0,-22} -> {1} refs" -f $k, $refs.Count) }
}

Write-Host "  structures emitted : $($themes.Count)"
if ($Apply) { Write-Host "  files written      : $written" -ForegroundColor Green }

if ($Apply) {
    $mdir = [System.IO.Path]::GetDirectoryName($Manifest)
    if (-not [System.IO.Directory]::Exists($mdir)) { [System.IO.Directory]::CreateDirectory($mdir) | Out-Null }
    [System.IO.File]::WriteAllLines($Manifest, $manifestLines, $Utf8NoBom)
    Write-Host "  manifest           : $Manifest"
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
