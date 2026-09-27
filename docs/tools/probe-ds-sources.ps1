# Probe: locate Dragon Survival source files relevant to the kubejs customisation surface.
# ASCII-only on purpose (PowerShell 5.1 reads BOM-less files as ANSI).
$root = 'D:\Minecraft\开源模组参考文件\DragonSurvival\src\main\java'
if (-not (Test-Path -LiteralPath $root)) {
    Write-Host "MAIN JAVA ROOT MISSING: $root"
    Get-ChildItem -LiteralPath 'D:\Minecraft\开源模组参考文件\DragonSurvival\src' -Directory | Select-Object -ExpandProperty FullName
    exit 1
}

$patterns = @(
    'DragonSpecies.java',
    'DragonAbility.java',
    'DragonStage.java',
    'DragonPenalty.java',
    'DragonBody.java',
    'Modifier.java',
    'DietEntry.java',
    'DragonGrowthUpgrade.java',
    'LevelBasedResource.java'
)

Write-Host "=== target files ==="
foreach ($p in $patterns) {
    $hits = Get-ChildItem -LiteralPath $root -Recurse -File -Filter $p -ErrorAction SilentlyContinue
    if ($hits) { $hits | ForEach-Object { $_.FullName } }
    else { Write-Host "  (not found) $p" }
}

Write-Host ""
Write-Host "=== registry dir listing ==="
Get-ChildItem -LiteralPath (Join-Path $root 'by/dragonsurvivalteam/dragonsurvival') -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name
