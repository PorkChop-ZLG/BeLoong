# Enumerate dragon_penalty JSONs across Dragon Survival + its addon jars.
# ASCII-only on purpose (PowerShell 5.1 reads BOM-less scripts as ANSI).
Add-Type -AssemblyName System.IO.Compression.FileSystem

$mods = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'mods'

# DS本体 + [龙之生存...] addons ; the prefix is non-ASCII so match by a byte-safe substring instead.
$jars = Get-ChildItem -LiteralPath $mods -File | Where-Object {
    $_.Name -like '*DragonSurvival*' -or
    $_.Name -like '*ds_aether_addon*' -or
    $_.Name -like '*tundradragon*' -or
    $_.Name -like '*frostfire_dragon*' -or
    $_.Name -like '*crystcursed_dragon*' -or
    $_.Name -like '*annihilator_type_a*' -or
    $_.Name -like '*astral_dragon*' -or
    $_.Name -like '*star_dragon*' -or
    $_.Name -like '*wing_kirin*' -or
    $_.Name -like '*ds_night_striker*' -or
    $_.Name -like '*dragon_survival_iaf*' -or
    $_.Name -like '*dragon_barrel_roll*'
}

Write-Host "Candidate jars: $($jars.Count)"
Write-Host ""

foreach ($jar in $jars) {
    $zip = $null
    try { $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName) } catch { continue }

    $entries = $zip.Entries | Where-Object {
        $_.FullName -match '^data/[^/]+/dragonsurvival/dragon_penalty/[^/]+\.json$'
    }

    if ($entries) {
        Write-Host "=== $($jar.Name) ==="
        foreach ($e in $entries) {
            $reader = New-Object System.IO.StreamReader($e.Open())
            $text = $reader.ReadToEnd()
            $reader.Close()
            $flat = ($text -replace '\s+', ' ').Trim()
            if ($flat.Length -gt 150) { $flat = $flat.Substring(0, 150) + '...' }
            Write-Host "  ENTRY : $($e.FullName)"
            Write-Host "  BODY  : $flat"
            Write-Host ""
        }
    }

    if ($zip) { $zip.Dispose() }
}
Write-Host "Done."
