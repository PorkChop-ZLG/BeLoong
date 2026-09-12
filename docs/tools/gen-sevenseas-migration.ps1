# gen-sevenseas-migration.ps1
# Migrate dungeons_arise_seven_seas (5 ships) into beloong:disaster exclusively.
#
# Design decisions (user-approved):
#   - Target biome tag: #beloong:disaster/is_ocean  (single reference, no multi-theme)
#   - New structure set: beloong:disaster_sea_set
#   - placement: spacing 40 / separation 34 / salt 98123789 (original salt kept)
#   - weights: all five ships = 1 (same as the expansion's original set)
#   - NO exclusion_zone (all disaster-dimension structures are designed not to overlap;
#     a MUTUAL exclusion pair causes unbounded recursion -> StackOverflowError)
#   - Original set dungeons_arise_seven_seas:minor_structures is emptied
#     => the ships then generate ONLY in beloong:disaster
#
# NOTE: 100% ASCII BY DESIGN (Windows PowerShell 5.1 reads .ps1 as ANSI when no BOM is
#       present, which corrupts non-ASCII literals including non-ASCII file paths).
#       All paths are resolved at RUNTIME; all output text is English.
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-sevenseas-migration.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-sevenseas-migration.ps1 -Apply

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ---------------------------------------------------------------- path resolution (runtime, ASCII-safe)
$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ModsDir = Join-Path $Root 'mods'

# The expansion jar's name contains 'DungeonsAriseSevenSeas'; the base mod's does not.
# -Filter/-Path wildcards are unreliable here (fullwidth brackets in sibling filenames),
# so filter with Where-Object -like.
$SeaJar = (Get-ChildItem -LiteralPath $ModsDir -File |
              Where-Object { $_.Name -like '*SevenSeas*.jar' } |
              Select-Object -First 1).FullName
if (-not $SeaJar) { throw 'SevenSeas jar not found under mods' }

$SeaNs     = 'dungeons_arise_seven_seas'
$TagOutDir = Join-Path $Root 'kubejs\data\dungeons_arise_seven_seas\tags\worldgen\biome\has_structure'
$SetOutDir = Join-Path $Root 'kubejs\data\beloong\worldgen\structure_set'
$SeaSetDir = Join-Path $Root 'kubejs\data\dungeons_arise_seven_seas\worldgen\structure_set'
$SeaSetFile= Join-Path $SeaSetDir 'minor_structures.json'
$TargetTag = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\disaster\is_ocean.json'
$DataDir   = Join-Path $Root 'kubejs\data'
$Manifest  = Join-Path $Root 'docs\tools\out\sevenseas-migration-manifest.txt'

$TargetRef = '#beloong:disaster/is_ocean'
$SetId     = 'beloong:disaster_sea_set'
$Spacing   = 40
$Separation= 34
$Salt      = 98123789

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

Write-Host ""
Write-Host "root    : $Root"
Write-Host "sea jar : $SeaJar"

# ================================================================ 1. enumerate from jar
Write-Host ""
Write-Host "=== 1. Enumerate ships from jar ===" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($SeaJar)

$ships = @($zip.Entries |
    Where-Object { $_.FullName -match "^data/$SeaNs/worldgen/structure/[^/]+\.json$" } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') } |
    Sort-Object)
Write-Host "  ships found: $($ships.Count) -> $($ships -join ', ')"
if ($ships.Count -ne 5) { Add-Fail "expected 5 ships, got $($ships.Count)" }

# each ship must reference its own has_structure tag
$shipTag = @{}
foreach ($e in ($zip.Entries | Where-Object { $_.FullName -match "^data/$SeaNs/worldgen/structure/[^/]+\.json$" })) {
    $r = New-Object System.IO.StreamReader($e.Open()); $txt = $r.ReadToEnd(); $r.Close()
    $nm = $e.FullName.Split('/')[-1].Replace('.json','')
    $m = [regex]::Match($txt, '"biomes"\s*:\s*"(#[^"]+)"')
    if (-not $m.Success) { Add-Fail "$nm has no '#...' biomes reference" ; continue }
    $shipTag[$nm] = $m.Groups[1].Value
}
foreach ($s in $ships) {
    $want = "#$SeaNs" + ":has_structure/" + $s + "_biomes"
    if ($shipTag[$s] -ne $want) { Add-Fail "$s biomes = $($shipTag[$s]), expected $want" }
}
if (-not $script:fail.Count) { Write-Host "  [OK] all 5 ships reference their own has_structure tag" -ForegroundColor Green }

# all five source tags must be identical and be #minecraft:is_ocean
$srcBodies = New-Object System.Collections.Generic.List[string]
foreach ($s in $ships) {
    $p = "data/$SeaNs/tags/worldgen/biome/has_structure/${s}_biomes.json"
    $e = $zip.Entries | Where-Object { $_.FullName -eq $p } | Select-Object -First 1
    if (-not $e) { Add-Fail "source tag missing in jar: $p"; continue }
    $r = New-Object System.IO.StreamReader($e.Open()); $txt = $r.ReadToEnd(); $r.Close()
    $norm = ($txt -replace '\s+','')
    $srcBodies.Add($norm)
    if ($norm -ne '{"replace":false,"values":["#minecraft:is_ocean"]}') {
        Write-Host "  note: $s source tag differs from expectation: $norm" -ForegroundColor DarkYellow
    }
}
$uniq = @($srcBodies | Sort-Object -Unique)
if ($uniq.Count -ne 1) { Add-Fail "the 5 source tags are not identical ($($uniq.Count) variants)" }
else { Write-Host "  [OK] all 5 source tags identical: $($uniq[0])" -ForegroundColor Green }
$zip.Dispose()

# ================================================================ 2. target tag must be ready
Write-Host ""
Write-Host "=== 2. Assert target theme tag is ready ===" -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $TargetTag)) { Add-Fail "target tag missing: $TargetTag" }
else {
    $tj = [System.IO.File]::ReadAllText($TargetTag, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $tv = @($tj.values)
    Write-Host "  $TargetRef : replace=$($tj.replace)  entries=$($tv.Count)"
    Write-Host "    $($tv -join ', ')"
    if ($tv.Count -eq 0) { Add-Fail "target tag is empty" }
    if ($tv -contains '#minecraft:is_ocean') { Add-Fail "target tag should hold bare biome IDs, not vanilla refs" }
}

# ================================================================ 3. emit has_structure overrides
Write-Host ""
Write-Host "=== 3. Emit has_structure overrides ===" -ForegroundColor Cyan
$tagJson = "{`r`n  `"replace`": true,`r`n  `"values`": [`r`n    `"$TargetRef`"`r`n  ]`r`n}`r`n"

$written = 0
foreach ($s in $ships) {
    $out = Join-Path $TagOutDir "${s}_biomes.json"
    if ($Apply) {
        if (-not [System.IO.Directory]::Exists($TagOutDir)) { [System.IO.Directory]::CreateDirectory($TagOutDir) | Out-Null }
        [System.IO.File]::WriteAllText($out, $tagJson, $Utf8NoBom)
        $written++
    }
    Write-Host "  ${s}_biomes.json -> $TargetRef"
}
Write-Host "  files written: $written"
if ($Apply -and $written -ne 5) { Add-Fail "expected to write 5 tag files, wrote $written" }

# ================================================================ 4. emit new structure set
Write-Host ""
Write-Host "=== 4. Emit $SetId ===" -ForegroundColor Cyan
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("{`r`n")
[void]$sb.Append("  `"placement`": {`r`n")
[void]$sb.Append("    `"type`": `"minecraft:random_spread`",`r`n")
[void]$sb.Append("    `"spacing`": $Spacing,`r`n")
[void]$sb.Append("    `"separation`": $Separation,`r`n")
[void]$sb.Append("    `"salt`": $Salt`r`n")
[void]$sb.Append("  },`r`n")
[void]$sb.Append("  `"structures`": [`r`n")
for ($i = 0; $i -lt $ships.Count; $i++) {
    $comma = if ($i -lt $ships.Count - 1) { ',' } else { '' }
    [void]$sb.Append("    { `"structure`": `"$SeaNs`:$($ships[$i])`", `"weight`": 1 }$comma`r`n")
}
[void]$sb.Append("  ]`r`n")
[void]$sb.Append("}`r`n")
$setJson = $sb.ToString()
$setPath = Join-Path $SetOutDir 'disaster_sea_set.json'

if ($Apply) {
    if (-not [System.IO.Directory]::Exists($SetOutDir)) { [System.IO.Directory]::CreateDirectory($SetOutDir) | Out-Null }
    [System.IO.File]::WriteAllText($setPath, $setJson, $Utf8NoBom)
    Write-Host "  written: $setPath" -ForegroundColor Green
    $vj = [System.IO.File]::ReadAllText($setPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if (@($vj.structures).Count -ne 5) { Add-Fail "round-trip: $SetId has $(@($vj.structures).Count) members, expected 5" }
    if ($vj.placement.spacing -ne $Spacing -or $vj.placement.separation -ne $Separation -or $vj.placement.salt -ne $Salt) { Add-Fail "round-trip: placement mismatch" }
    if ($vj.placement.exclusion_zone) { Add-Fail "round-trip: $SetId must NOT declare an exclusion_zone" }
    if (-not $script:fail.Count) { Write-Host "  [OK] round-trip verified (5 members, 40/34/$Salt, no exclusion_zone)" -ForegroundColor Green }
} else {
    Write-Host "  (dry-run) would write: $setPath"
}

# ================================================================ 5. RISK GATE: empty the original set
Write-Host ""
Write-Host "=== 5. RISK GATE: empty the original minor_structures set ===" -ForegroundColor Cyan
Write-Host "  After this, the 5 ships generate ONLY in beloong:disaster."

$gateOk = $true
if (-not $Apply) {
    Write-Host "  (dry-run: file-existence gate skipped; asserting in-memory content instead)"
    # in-memory content assertions (the real gate runs on -Apply)
    try {
        $imm = $setJson | ConvertFrom-Json
        $n = @($imm.structures).Count
        if ($n -ne 5) { Add-Fail "DRYRUN: emitted set has $n members, expected 5"; $gateOk = $false }
        else { Write-Host "  [OK] emitted set would have 5 members" -ForegroundColor Green }
        if ($imm.placement.spacing -ne $Spacing -or $imm.placement.separation -ne $Separation -or $imm.placement.salt -ne $Salt) {
            Add-Fail "DRYRUN: emitted placement mismatch"; $gateOk = $false
        } else { Write-Host "  [OK] emitted placement 40/34/$Salt" -ForegroundColor Green }
        if ($imm.placement.exclusion_zone) { Add-Fail "DRYRUN: emitted set must not declare exclusion_zone"; $gateOk = $false }
    } catch { Add-Fail "DRYRUN: emitted set JSON does not parse: $($_.Exception.Message)"; $gateOk = $false }
    try {
        $itj = $tagJson | ConvertFrom-Json
        if ($itj.replace -ne $true) { Add-Fail "DRYRUN: emitted tag replace must be true"; $gateOk = $false }
        if (@($itj.values).Count -ne 1 -or $itj.values[0] -ne $TargetRef) { Add-Fail "DRYRUN: emitted tag values wrong"; $gateOk = $false }
        else { Write-Host "  [OK] emitted tag: replace=true -> $TargetRef" -ForegroundColor Green }
    } catch { Add-Fail "DRYRUN: emitted tag JSON does not parse: $($_.Exception.Message)"; $gateOk = $false }
}

# precondition a: new set must exist (only meaningful when writing)
if ($Apply) {
    if (Test-Path -LiteralPath $setPath) {
        $chk = [System.IO.File]::ReadAllText($setPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        $n = @($chk.structures).Count
        if ($n -ne 5) { Add-Fail "GATE: $SetId has $n members, expected 5 -- refusing to empty the original set"; $gateOk = $false }
        else { Write-Host "  [OK] $SetId has 5 members" -ForegroundColor Green }
    } else {
        Add-Fail "GATE: $SetId does not exist -- refusing to empty the original set"
        $gateOk = $false
    }

    # precondition b: members exist in jar -- revalidate via the tag files we just wrote
    foreach ($s in $ships) {
        $p = Join-Path $TagOutDir "${s}_biomes.json"
        if (-not (Test-Path -LiteralPath $p)) { Add-Fail "GATE: override missing for $s"; $gateOk = $false }
    }
}

# precondition c: the original set must still be readable (for placement preservation) OR already emptied
$origPlacement = $null
$zip2 = [System.IO.Compression.ZipFile]::OpenRead($SeaJar)
$oe = $zip2.Entries | Where-Object { $_.FullName -eq "data/$SeaNs/worldgen/structure_set/minor_structures.json" } | Select-Object -First 1
if ($oe) {
    $r = New-Object System.IO.StreamReader($oe.Open()); $ot = $r.ReadToEnd(); $r.Close()
    $origPlacement = $ot | ConvertFrom-Json
    Write-Host "  original placement: spacing=$($origPlacement.placement.spacing) separation=$($origPlacement.placement.separation) salt=$($origPlacement.placement.salt)"
    if ($origPlacement.placement.spacing -ne 68 -or $origPlacement.placement.salt -ne 98123789) {
        Write-Host "  note: original placement differs from what was recorded in the design (68/60/98123789)" -ForegroundColor DarkYellow
    }
} else {
    Add-Fail "GATE: original minor_structures.json not found in jar"
    $gateOk = $false
}
$zip2.Dispose()

if (-not $gateOk) {
    Write-Host ""
    Write-Host "ABORT: gate preconditions failed; original set NOT touched" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

# preserve the original placement, empty the member list
$ob = New-Object System.Text.StringBuilder
[void]$ob.Append("{`r`n")
[void]$ob.Append("  `"structures`": [],`r`n")
[void]$ob.Append("  `"placement`": {`r`n")
[void]$ob.Append("    `"type`": `"$($origPlacement.placement.type)`",`r`n")
[void]$ob.Append("    `"spacing`": $($origPlacement.placement.spacing),`r`n")
[void]$ob.Append("    `"separation`": $($origPlacement.placement.separation),`r`n")
[void]$ob.Append("    `"salt`": $($origPlacement.placement.salt)`r`n")
[void]$ob.Append("  }")
if ($origPlacement.exclusion_zone) {
    [void]$ob.Append(",`r`n")
    [void]$ob.Append("  `"exclusion_zone`": {`r`n")
    [void]$ob.Append("    `"other_set`": `"$($origPlacement.exclusion_zone.other_set)`",`r`n")
    [void]$ob.Append("    `"chunk_count`": $($origPlacement.exclusion_zone.chunk_count)`r`n")
    [void]$ob.Append("  }`r`n")
} else {
    [void]$ob.Append("`r`n")
}
[void]$ob.Append("}`r`n")

if ($Apply) {
    if (-not [System.IO.Directory]::Exists($SeaSetDir)) { [System.IO.Directory]::CreateDirectory($SeaSetDir) | Out-Null }
    [System.IO.File]::WriteAllText($SeaSetFile, $ob.ToString(), $Utf8NoBom)
    Write-Host "  written: $SeaSetFile (structures: [])" -ForegroundColor Green
    $ck = [System.IO.File]::ReadAllText($SeaSetFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if (@($ck.structures).Count -ne 0) { Add-Fail "round-trip: original set still has $($ck.structures.Count) members" }
    else { Write-Host "  [OK] original set emptied, placement preserved" -ForegroundColor Green }
} else {
    Write-Host "  (dry-run) would write: $SeaSetFile (structures: [])"
}

# ================================================================ 6. regression: no mutual exclusion
Write-Host ""
Write-Host "=== 6. Regression: no mutual exclusion pair in the pack ===" -ForegroundColor Cyan
$refs = @{}
$dataRoot = (Resolve-Path -LiteralPath $DataDir).Path
foreach ($f in (Get-ChildItem -LiteralPath $DataDir -Recurse -File -Filter *.json)) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($txt, '"other_set"\s*:\s*"([^"]+)"')
    if ($m.Success) {
        $ns = ($f.FullName.Substring($dataRoot.Length + 1) -split '\\')[0]
        $refs[($ns + ':' + $f.BaseName)] = $m.Groups[1].Value
    }
}
Write-Host "  exclusion_zone references: $($refs.Count)"
$cycles = @()
foreach ($k in $refs.Keys) { $v = $refs[$k]; if ($refs.ContainsKey($v) -and $refs[$v] -eq $k) { $cycles += "$k <-> $v" } }
if ($cycles.Count) { Add-Fail "mutual exclusion cycle(s): $($cycles -join ' ; ')" }
else { Write-Host "  [OK] all references one-way" -ForegroundColor Green }

# ================================================================ 7. manifest
if ($Apply) {
    $ml = New-Object System.Collections.Generic.List[string]
    $ml.Add("# seven_seas -> disaster migration manifest")
    $ml.Add("# AUTO-GENERATED. no exclusion_zone anywhere by design.")
    $ml.Add("")
    $ml.Add("target tag : $TargetRef")
    $ml.Add("new set    : $SetId  spacing=$Spacing separation=$Separation salt=$Salt")
    $ml.Add("")
    foreach ($s in $ships) { $ml.Add(("{0}:{1}`tweight=1`t-> {2}" -f $SeaNs, $s, $TargetRef)) }
    $ml.Add("")
    $ml.Add("original set emptied: " + $SeaNs + ":minor_structures")
    $mdir = [System.IO.Path]::GetDirectoryName($Manifest)
    if (-not [System.IO.Directory]::Exists($mdir)) { [System.IO.Directory]::CreateDirectory($mdir) | Out-Null }
    [System.IO.File]::WriteAllLines($Manifest, $ml, $Utf8NoBom)
    Write-Host ""
    Write-Host "  manifest: $Manifest"
}

# ================================================================ summary
Write-Host ""
if ($script:fail.Count -gt 0) {
    Write-Host "=== FAILED: $($script:fail.Count) ===" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "[OK] all assertions passed" -ForegroundColor Green
if (-not $Apply) { Write-Host "(dry-run; no files written. Add -Apply to write.)" -ForegroundColor Yellow }
exit 0
