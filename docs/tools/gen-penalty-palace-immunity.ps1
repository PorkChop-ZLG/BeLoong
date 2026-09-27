# Generate palace-immune dragon_penalty overrides from DS本体 + [龙之生存：] addons.
# ASCII-only on purpose (PowerShell 5.1 reads BOM-less scripts as ANSI).
#
# Usage:
#   .\gen-penalty-palace-immunity.ps1            # dry run: report only
#   .\gen-penalty-palace-immunity.ps1 -Apply     # write files
param([switch]$Apply)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Mods   = Join-Path $Root 'mods'
$Kubejs = Join-Path $Root 'kubejs\data'

# ---- penalty -> source jar matcher + destination relative path -----------------
# Destinations follow the namespace the penalty id already lives in.
$Spec = @(
    @{ id='dragonsurvival:cold_weakness';                  jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\cold_weakness.json' }
    @{ id='dragonsurvival:fear_of_darkness';               jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\fear_of_darkness.json' }
    @{ id='dragonsurvival:thin_skin';                      jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\thin_skin.json' }
    @{ id='dragonsurvival:water_weakness';                 jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\water_weakness.json' }
    @{ id='dragonsurvival:heat_weakness';                  jar='*tundradragon*';                       dest='dragonsurvival\dragonsurvival\dragon_penalty\heat_weakness.json' }
    @{ id='dragonsurvival:melting_point';                  jar='*tundradragon*';                       dest='dragonsurvival\dragonsurvival\dragon_penalty\melting_point.json' }
    @{ id='dragonsurvival:gravity_well';                   jar='*astral_dragon*';                      dest='dragonsurvival\dragonsurvival\dragon_penalty\gravity_well.json' }
    @{ id='dragonsurvival:inediate';                       jar='*astral_dragon*';                      dest='dragonsurvival\dragonsurvival\dragon_penalty\inediate.json' }
    @{ id='dragonsurvival:night_striker_fear_1';           jar='*ds_night_striker*';                   dest='dragonsurvival\dragonsurvival\dragon_penalty\night_striker_fear_1.json' }
    @{ id='dragonsurvival:night_striker_fear_2';           jar='*ds_night_striker*';                   dest='dragonsurvival\dragonsurvival\dragon_penalty\night_striker_fear_2.json' }
    @{ id='dragonsurvival:night_striker_hunger';           jar='*ds_night_striker*';                   dest='dragonsurvival\dragonsurvival\dragon_penalty\night_striker_hunger.json' }
    @{ id='star_dragon:starlight_flux';                    jar='*star_dragon*';                        dest='star_dragon\dragonsurvival\dragon_penalty\starlight_flux.json' }
    @{ id='dragonsurvival:impact_weakness';                jar='*tundradragon*';                       dest='dragonsurvival\dragonsurvival\dragon_penalty\impact_weakness.json' }
    @{ id='dragonsurvival:snowball_weakness';              jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\snowball_weakness.json' }
    @{ id='dragonsurvival:water_potion_weakness';          jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\water_potion_weakness.json' }
    @{ id='dragonsurvival:water_splash_potion_weakness';   jar='*DragonSurvival-1.21.1*';              dest='dragonsurvival\dragonsurvival\dragon_penalty\water_splash_potion_weakness.json' }
    @{ id='dragonsurvival:flight_limit';                   jar='*dihuang*';                            dest='dragonsurvival\dragonsurvival\dragon_penalty\flight_limit.json' }
    @{ id='dragonsurvival:mineral_dependency';             jar='*dihuang*';                            dest='dragonsurvival\dragonsurvival\dragon_penalty\mineral_dependency.json' }
)

# Copied verbatim, no immunity (generic penalty: "龙威")
$CopyOnly = @(
    @{ id='dragonsurvival:fear'; jar='*DragonSurvival-1.21.1*'; dest='dragonsurvival\dragonsurvival\dragon_penalty\fear.json' }
)

# Already customised by the project -> never overwrite
# (dihuang's flight_limit / mineral_dependency moved into $Spec: they are plain
#  jar definitions, but the project's kubejs tag override only keeps flight_limit.
#  See the note printed after generation.)
$Skip = @(
    'dragonsurvival:batophobia'
    'dragonsurvival:source_emptiness'
    'wing_kirin:evil_entangle'
    'dragonsurvival:item_blacklist'
    'dragonsurvival:night_striker_item_blacklist'
)

# Vanilla LootItemCondition type names (no namespace). Used ONLY to normalise
# un-namespaced values; anything outside this list is reported, never rewritten.
$VanillaPrefixes = @(
    'all_of','any_of','inverted','entity_properties','location_check','block_state_property',
    'damage_source_properties','entity_scores','killed_by_player','match_tool','random_chance',
    'random_chance_with_looting','reference','survives_explosion','table_bonus','time_check',
    'value_check','weather_check','enchantment_active_check'
)

function Get-Penalty-Tree {
    param([string]$Id, [string]$JarPattern)
    $ns, $name = $Id -split ':'
    $entryPath = "data/$ns/dragonsurvival/dragon_penalty/$name.json"

    $jar = Get-ChildItem -LiteralPath $Mods -File |
           Where-Object { $_.Name -like $JarPattern } |
           Select-Object -First 1
    if (-not $jar) { throw "jar not found for pattern $JarPattern" }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
    try {
        $e = $zip.Entries | Where-Object { $_.FullName -eq $entryPath }
        if (-not $e) { throw "entry not found: $entryPath in $($jar.Name)" }
        $r = New-Object System.IO.StreamReader($e.Open())
        $text = $r.ReadToEnd()
        $r.Close()
    } finally { $zip.Dispose() }

    return ($text | ConvertFrom-Json)
}

function Set-VanillaPrefixes {
    param($Node, [ref]$Count)
    if ($Node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $Node.PSObject.Properties) {
            if ($p.Name -eq 'condition' -and $p.Value -is [string]) {
                $v = $p.Value
                if ($v -notmatch ':') {
                    if ($VanillaPrefixes -contains $v) {
                        $p.Value = "minecraft:$v"
                        $Count.Value = $Count.Value + 1
                    } else {
                        Write-Warning "un-namespaced condition not in vanilla whitelist, left as-is: '$v'"
                    }
                }
            } else {
                Set-VanillaPrefixes $p.Value $Count
            }
        }
    } elseif ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) { Set-VanillaPrefixes $item $Count }
    }
}

function Get-ImmunityTerm {
    [ordered]@{
        condition = 'minecraft:location_check'
        predicate = [ordered]@{ dimension = 'beloong:loong_palace' }
    }
}

function Add-PalaceImmunity {
    param($Tree, [ref]$Strategy)

    if (-not $Tree.PSObject.Properties['condition']) {
        # No condition at all -> add a standalone inverted one so it never fires in the palace
        $Tree | Add-Member -NotePropertyName 'condition' -NotePropertyValue ([ordered]@{
            condition = 'minecraft:inverted'
            term      = Get-ImmunityTerm
        })
        $Strategy.Value = 'ADDED-STANDALONE'
        return
    }

    $cond = $Tree.condition

    # Shape A: inverted -> any_of [...]  == "none of these apply". Push a palace term into any_of.
    if ($cond.condition -eq 'minecraft:inverted' -and
        $cond.term -and $cond.term.condition -eq 'minecraft:any_of' -and
        $cond.term.terms) {
        $existing = @($cond.term.terms)
        $cond.term.terms = @((Get-ImmunityTerm)) + $existing
        $Strategy.Value = 'ANY_OF-TERM'
        return
    }

    # Shape B: all_of -> prepend a palace term
    if ($cond.condition -eq 'minecraft:all_of' -and $cond.terms) {
        $existing = @($cond.terms)
        $cond.terms = @((Get-ImmunityTerm)) + $existing
        $Strategy.Value = 'ALL_OF-TERM'
        return
    }

    # Shape C: any other self-contained condition -> wrap in all_of with palace immunity
    $Tree.condition = [ordered]@{
        condition = 'minecraft:all_of'
        terms     = @(
            (Get-ImmunityTerm)
            $cond
        )
    }
    $Strategy.Value = 'WRAP-ALL_OF'
}

# ------------------------------------------------------------------------------
$results = @()

Write-Host "=== IMMUNITY TARGETS ==="
foreach ($s in $Spec) {
    $tree = Get-Penalty-Tree -Id $s.id -JarPattern $s.jar

    $prefixCount = 0
    Set-VanillaPrefixes $tree ([ref]$prefixCount)

    $strategy = ''
    Add-PalaceImmunity $tree ([ref]$strategy)

    $destPath = Join-Path $Kubejs $s.dest
    $json = $tree | ConvertTo-Json -Depth 100

    if ($Apply) {
        $dir = Split-Path -Parent $destPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -LiteralPath $destPath -Value $json -Encoding UTF8
    }

    $results += [pscustomobject]@{ id=$s.id; strategy=$strategy; prefixes=$prefixCount; dest=$s.dest }
    "{0,-45} {1,-16} prefixes={2}" -f $s.id, $strategy, $prefixCount
}

Write-Host ""
Write-Host "=== COPY-ONLY (no immunity) ==="
foreach ($s in $CopyOnly) {
    $ns, $name = $s.id -split ':'
    $jar = Get-ChildItem -LiteralPath $Mods -File | Where-Object { $_.Name -like $s.jar } | Select-Object -First 1
    $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
    try {
        $e = $zip.Entries | Where-Object { $_.FullName -eq "data/$ns/dragonsurvival/dragon_penalty/$name.json" }
        # Byte-identical copy: "verbatim" means verbatim, including indentation style.
        $ms = New-Object System.IO.MemoryStream
        $st = $e.Open(); $st.CopyTo($ms); $st.Close()
        $bytes = $ms.ToArray()
    } finally { $zip.Dispose() }

    $destPath = Join-Path $Kubejs $s.dest
    if ($Apply) {
        $dir = Split-Path -Parent $destPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes($destPath, $bytes)
    }
    "{0,-45} {1,-16} bytes={2}" -f $s.id, 'COPY-ONLY', $bytes.Length
}

Write-Host ""
Write-Host "=== SKIPPED (already customised / out of scope) ==="
$Skip | ForEach-Object { "  $_" }

Write-Host ""
if ($Apply) { Write-Host "APPLIED. Files written." } else { Write-Host "DRY RUN. Re-run with -Apply to write." }

