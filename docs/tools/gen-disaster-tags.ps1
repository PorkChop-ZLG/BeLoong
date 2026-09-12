# gen-disaster-tags.ps1
# Generate disaster-dimension theme tags: beloong:disaster/*
#
# Design ref: docs/plans/2026-09-21-dungeons-arise-disaster-migration-design.md section 2.2
#
# Hard constraints:
#   1) Content MUST be enumerated from source data, never hand-transcribed.
#   2) Theme tags use replace:false (brand-new self-made tags, no upstream entries).
#   3) Core-mod custom biomes go at the TOP of the values array.
#
# IMPORTANT: This file is 100% ASCII BY DESIGN.
#   Windows PowerShell 5.1 reads .ps1 as ANSI when no BOM is present, which corrupts
#   any non-ASCII literal (including non-ASCII file paths). All paths are therefore
#   resolved at RUNTIME via wildcard enumeration, and all output text is English.
#
# Usage (run from the instance root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-disaster-tags.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs\tools\gen-disaster-tags.ps1 -Apply

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ---------------------------------------------------------------- path resolution (runtime, ASCII-safe)
$Root     = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # docs\tools -> instance root
$ModsDir  = Join-Path $Root 'mods'
# NOTE: -Filter / -Path wildcards fail on filenames containing fullwidth or square
# brackets (8.3 short-name matching). Where-Object -like is reliable.
$BwgJar   = (Get-ChildItem -LiteralPath $ModsDir -File |
                Where-Object { $_.Name -like '*Biomes-Weve-Gone-NeoForge-*.jar' } |
                Select-Object -First 1).FullName
$CoreJar  = (Get-ChildItem -LiteralPath $ModsDir -File |
                Where-Object { $_.Name -like 'beloong-*.jar' } |
                Select-Object -First 1).FullName
$RefRoot  = 'D:\Minecraft'
$BwgSrc   = (Get-ChildItem -LiteralPath $RefRoot -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName 'Common\src\main\generated\resources\data\biomeswevegone\tags\worldgen\biome' } |
                Where-Object { Test-Path -LiteralPath $_ } |
                Select-Object -First 1)
$OutDir   = Join-Path $Root 'kubejs\data\beloong\tags\worldgen\biome\disaster'
$Manifest = Join-Path $Root 'docs\tools\out\disaster-tags-manifest.txt'

if (-not $BwgJar)  { throw 'BWG jar not found under mods' }
if (-not $CoreJar) { throw 'core mod jar not found under mods' }
if (-not $BwgSrc)  { throw 'BWG source tags dir not found under D:\Minecraft' }

$BwgNs  = 'biomeswevegone:'
$CoreNs = 'beloong:'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:fail = New-Object System.Collections.Generic.List[string]
function Add-Fail([string]$m) { $script:fail.Add($m); Write-Host "  [FAIL] $m" -ForegroundColor Red }

Write-Host ""
Write-Host "root: $Root"
Write-Host "  BwgJar  = $BwgJar"
Write-Host "  CoreJar = $CoreJar"
Write-Host "  BwgSrc  = $BwgSrc"

# ---------------------------------------------------------------- 1. BWG biome universe (from jar)
Write-Host ""
Write-Host "=== 1. BWG biome universe (from jar) ===" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($BwgJar)
$bwgBiomes = $zip.Entries |
    Where-Object { $_.FullName -match '^data/biomeswevegone/worldgen/biome/[^/]+\.json$' } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') } |
    Sort-Object
$zip.Dispose()
Write-Host "  BWG biome count: $($bwgBiomes.Count)"
if ($bwgBiomes.Count -ne 55) { Add-Fail "Expected 55 BWG biomes, got $($bwgBiomes.Count)" }

$owPath = Join-Path $BwgSrc 'overworld.json'
$owList = (Get-Content -LiteralPath $owPath -Raw -Encoding UTF8 | ConvertFrom-Json).values |
    ForEach-Object { if ($_ -is [string]) { $_ } else { $_.id } } |
    ForEach-Object { $_.Replace($BwgNs,'') } | Sort-Object
$d1 = @($bwgBiomes | Where-Object { $owList -notcontains $_ })
$d2 = @($owList    | Where-Object { $bwgBiomes -notcontains $_ })
if ($d1.Count -or $d2.Count) {
    Add-Fail "biome dir vs overworld tag mismatch: dir-only [$($d1 -join ',')] tag-only [$($d2 -join ',')]"
} else {
    Write-Host "  [OK] bidirectional diff vs biomeswevegone:overworld is empty" -ForegroundColor Green
}

# ---------------------------------------------------------------- 2. core-mod custom biomes (from jar)
Write-Host ""
Write-Host "=== 2. Core-mod custom biomes (from jar) ===" -ForegroundColor Cyan
$zip = [System.IO.Compression.ZipFile]::OpenRead($CoreJar)
$coreAll = $zip.Entries |
    Where-Object { $_.FullName -match '^data/beloong/worldgen/biome/[^/]+\.json$' } |
    ForEach-Object { $_.FullName.Split('/')[-1].Replace('.json','') } |
    Sort-Object
$zip.Dispose()
Write-Host "  found: $($coreAll -join ', ')"
$gotCore  = @($coreAll | Where-Object { $_ -ne 'loong_palace' })
$wantCore = @('caves','frozen_ocean','ocean','river','windswept')
$d1 = @($wantCore | Where-Object { $gotCore -notcontains $_ })
$d2 = @($gotCore  | Where-Object { $wantCore -notcontains $_ })
if ($d1.Count -or $d2.Count) {
    Add-Fail "custom biome set mismatch: missing [$($d1 -join ',')] extra [$($d2 -join ',')]"
} else {
    Write-Host "  [OK] 5 custom biomes match expectation (loong_palace excluded)" -ForegroundColor Green
}

# ---------------------------------------------------------------- 3. recursive BWG tag expansion
Write-Host ""
Write-Host "=== 3. Expand BWG tags recursively ===" -ForegroundColor Cyan
$script:SrcRoot = $BwgSrc
$script:Ns      = $BwgNs
$script:cache   = @{}
function Get-BwgTag([string]$name) {
    if ($script:cache.ContainsKey($name)) { return $script:cache[$name] }
    $p = Join-Path $script:SrcRoot ($name.Replace('/','\') + '.json')
    if (-not (Test-Path -LiteralPath $p)) { Add-Fail "missing source tag: $name"; return @() }
    $vals = (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json).values
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($v in $vals) {
        $id = if ($v -is [string]) { $v } else { $v.id }
        if ($id -like '#*') {
            $sub = $id.Substring(1)
            if ($sub -like "$($script:Ns)*") {
                foreach ($x in (Get-BwgTag $sub.Replace($script:Ns,''))) { $out.Add($x) }
            } else {
                Write-Host "    [warn] $name references non-BWG tag $id (skipped)" -ForegroundColor DarkYellow
            }
        } else {
            if ($id -like "$($script:Ns)*") { $out.Add($id.Replace($script:Ns,'')) }
            else { Write-Host "    [warn] $name contains non-BWG biome $id (skipped)" -ForegroundColor DarkYellow }
        }
    }
    $res = @($out | Sort-Object -Unique)
    $script:cache[$name] = $res
    return $res
}

# ---------------------------------------------------------------- 4. 31 theme definitions
Write-Host ""
Write-Host "=== 4. Build 13 theme tags ===" -ForegroundColor Cyan
$themes = @(
    @{ Id='is_desert';                      Bwg='desert';            Core=@() }
    @{ Id='is_plains';                      Bwg='plains';            Core=@() }
    @{ Id='is_swamp';                       Bwg='swamp';             Core=@() }
    @{ Id='is_mountain';                    Bwg='mountain';          Core=@() }
    @{ Id='is_windswept';                   Bwg='windswept';         Core=@('beloong:windswept') }
    @{ Id='is_snowy';                       Bwg='snowy';             Core=@() }
    @{ Id='is_forest';                      Bwg='forest';            Core=@() }
    @{ Id='is_taiga';                       Bwg='taiga';             Core=@() }
    @{ Id='is_jungle';                      Bwg='jungle';            Core=@() }
    @{ Id='is_badlands';                    Bwg='badlands';          Core=@() }
    @{ Id='is_ocean';                       Bwg='ocean';             Core=@('beloong:frozen_ocean','beloong:ocean') }
    @{ Id='is_beach';                       Bwg='beach';             Core=@() }
    @{ Id='is_hill';                        Bwg=$null;               Core=@('beloong:windswept') }
)

if ($themes.Count -ne 13) { Add-Fail "Expected 13 theme definitions, got $($themes.Count)" }

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("# beloong:disaster/* theme tag manifest")
$manifestLines.Add("# AUTO-GENERATED. Do not hand-edit. Design ref: design.md section 2.2")
$manifestLines.Add("")

$written = 0
foreach ($t in $themes) {
    $bwgList  = if ($t.Bwg) { @(Get-BwgTag $t.Bwg) } else { @() }
    $coreList = @($t.Core)

    foreach ($c in $coreList) {
        if ($gotCore -notcontains $c.Replace($CoreNs,'')) { Add-Fail "$($t.Id): custom biome not registered: $c" }
    }
    foreach ($b in $bwgList) {
        if ($bwgBiomes -notcontains $b) { Add-Fail "$($t.Id): BWG biome not registered: $b" }
    }

    $values = @($coreList) + @($bwgList | ForEach-Object { "$BwgNs$_" })
    if ($values.Count -eq 0) { Add-Fail "$($t.Id): values is empty" }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('{')
    $lines.Add('  "replace": false,')
    $lines.Add('  "values": [')
    for ($i = 0; $i -lt $values.Count; $i++) {
        $comma = if ($i -lt $values.Count - 1) { ',' } else { '' }
        $lines.Add("    `"$($values[$i])`"$comma")
    }
    $lines.Add('  ]')
    $lines.Add('}')
    $json = ($lines -join "`r`n") + "`r`n"

    $outPath = Join-Path $OutDir ($t.Id.Replace('/','\') + '.json')
    if ($Apply) {
        $dir = Split-Path $outPath -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($outPath, $json, $Utf8NoBom)
        $written++
    }
    $tagId = "beloong:disaster/$($t.Id)"
    Write-Host ("  {0,-34} core {1,2} + bwg {2,2} = {3,2}" -f $tagId, $coreList.Count, $bwgList.Count, $values.Count)
    $manifestLines.Add(("{0}`tcore={1}`tbwg={2}`ttotal={3}`t{4}" -f $tagId, $coreList.Count, $bwgList.Count, $values.Count, ($values -join ' ')))
}

# ---------------------------------------------------------------- 5. summary
Write-Host ""
Write-Host "=== 5. Summary ===" -ForegroundColor Cyan
Write-Host "  theme definitions : $($themes.Count)"
if ($Apply) { Write-Host "  files written     : $written" -ForegroundColor Green }

$manifestLines.Add("")
$manifestLines.Add("# total theme tags: $($themes.Count)")
if ($Apply) {
    $mdir = [System.IO.Path]::GetDirectoryName($Manifest)
    if (-not [System.IO.Directory]::Exists($mdir)) { [System.IO.Directory]::CreateDirectory($mdir) | Out-Null }
    [System.IO.File]::WriteAllLines($Manifest, $manifestLines, $Utf8NoBom)
    Write-Host "  manifest written  : $Manifest"
}

if ($script:fail.Count -gt 0) {
    Write-Host ""
    Write-Host "=== FAILED: $($script:fail.Count) ===" -ForegroundColor Red
    $script:fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host ""
    Write-Host "[OK] all assertions passed" -ForegroundColor Green
    if (-not $Apply) { Write-Host "(dry-run; no files written. Add -Apply to write.)" -ForegroundColor Yellow }
    exit 0
}
