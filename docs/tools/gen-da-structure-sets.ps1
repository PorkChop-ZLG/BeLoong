# gen-da-structure-sets.ps1
# Create beloong:disaster_set_ground and beloong:disaster_set_underground.
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md section 2.7
#
# Params (approved):
#   ground      : spacing 32, separation 16, salt 20260921, exclusion -> underground(10)
#   underground : spacing 32, separation 16, salt 20260922, exclusion -> ground(10)
#   exclusion_zone is a SINGLE-VALUE field (verified: 12 structure sets in the instance use
#   it, 0 use more than one). minecraft:strongholds was dropped for that reason.
#
# Weights (approved): ground 7/12/10 ; underground all 2 ; total 7/16/10 = 33
#   3 = small/ambient, 2 = standard dungeon, 1 = major landmark/boss
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

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

if (-not $DaJar) { throw 'DungeonsArise jar not found under mods' }

$EndMigrated = @('aviary','keep_kayra','heavenly_rider','heavenly_conqueror','heavenly_challenger')
$Deleted     = @('giant_mushroom','mining_system','small_prairie_house')
$Underground = @('foundry','mining_complex','plague_asylum','infested_temple')

$Weight3 = @('fishing_hut','wishing_well','bathhouse','merchant_campsite','illager_campsite',
             'small_blimp','lighthouse','jungle_tree_house','abandoned_temple','mushroom_house')
$Weight1 = @('coliseum','monastery','shiraz_palace','bandit_village','illager_corsair',
             'illager_galley','typhon')

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
Write-Host "=== 2. Validate weight table ===" -ForegroundColor Cyan
$script:Weight1 = $Weight1
$script:Weight3 = $Weight3
function Get-Weight([string]$s) {
    if ($script:Weight1 -contains $s) { return 1 }
    if ($script:Weight3 -contains $s) { return 3 }
    return 2
}
$members = @($ground) + @($Underground)
$w1 = @($members | Where-Object { $Weight1 -contains $_ })
$w3 = @($members | Where-Object { $Weight3 -contains $_ })
$w2 = @($members | Where-Object { $Weight1 -notcontains $_ -and $Weight3 -notcontains $_ })
Write-Host "  weight 1: $($w1.Count)   weight 2: $($w2.Count)   weight 3: $($w3.Count)   total: $($w1.Count + $w2.Count + $w3.Count)"
$g1 = @($ground | Where-Object { $Weight1 -contains $_ }).Count
$g2 = @($ground | Where-Object { $w2 -contains $_ }).Count
$g3 = @($ground | Where-Object { $Weight3 -contains $_ }).Count
Write-Host "  ground breakdown: w1=$g1 w2=$g2 w3=$g3 (sum $($g1+$g2+$g3))"
if (($g1 + $g2 + $g3) -ne 29) { Add-Fail "ground weight breakdown sums to $($g1+$g2+$g3), expected 29" }
if ($g1 -ne 7 -or $g2 -ne 12 -or $g3 -ne 10) { Add-Fail "ground weights should be 7/12/10, got $g1/$g2/$g3" }
if (($w1.Count + $w2.Count + $w3.Count) -ne 33) { Add-Fail "weight total = $($w1.Count+$w2.Count+$w3.Count), expected 33" }

function New-SetJson([object[]]$entries, [int]$spacing, [int]$separation, [long]$salt, [string]$excludeSet) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("{`r`n")
    [void]$sb.Append("  `"placement`": {`r`n")
    [void]$sb.Append("    `"type`": `"minecraft:random_spread`",`r`n")
    [void]$sb.Append("    `"spacing`": $spacing,`r`n")
    [void]$sb.Append("    `"separation`": $separation,`r`n")
    [void]$sb.Append("    `"salt`": $salt,`r`n")
    [void]$sb.Append("    `"exclusion_zone`": {`r`n")
    [void]$sb.Append("      `"other_set`": `"$excludeSet`",`r`n")
    [void]$sb.Append("      `"chunk_count`": 10`r`n")
    [void]$sb.Append("    }`r`n")
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

$groundJson = New-SetJson $groundEntries 32 16 20260921 'beloong:disaster_set_underground'
$underJson  = New-SetJson $underEntries  32 16 20260922 'beloong:disaster_set_ground'

Write-Host ""
Write-Host "=== 3. Emit structure sets ===" -ForegroundColor Cyan
if ($Apply) {
    if (-not [System.IO.Directory]::Exists($OutDir)) { [System.IO.Directory]::CreateDirectory($OutDir) | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path $OutDir 'disaster_set_ground.json'), $groundJson, $Utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $OutDir 'disaster_set_underground.json'), $underJson, $Utf8NoBom)
    Write-Host "  written: disaster_set_ground.json ($($groundEntries.Count) entries)" -ForegroundColor Green
    Write-Host "  written: disaster_set_underground.json ($($underEntries.Count) entries)" -ForegroundColor Green

    $gj = Get-Content -LiteralPath (Join-Path $OutDir 'disaster_set_ground.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $uj = Get-Content -LiteralPath (Join-Path $OutDir 'disaster_set_underground.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($gj.structures).Count -ne 29) { Add-Fail "ground round-trip = $(@($gj.structures).Count), expected 29" }
    if (@($uj.structures).Count -ne 4)  { Add-Fail "underground round-trip = $(@($uj.structures).Count), expected 4" }
    if ($gj.placement.spacing -ne 32 -or $gj.placement.separation -ne 16) { Add-Fail "ground placement wrong" }
    if ($gj.placement.exclusion_zone.other_set -ne 'beloong:disaster_set_underground') { Add-Fail "ground exclusion wrong" }
    if ($uj.placement.exclusion_zone.other_set -ne 'beloong:disaster_set_ground') { Add-Fail "underground exclusion wrong" }
    Write-Host "  [OK] round-trip verified" -ForegroundColor Green
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
