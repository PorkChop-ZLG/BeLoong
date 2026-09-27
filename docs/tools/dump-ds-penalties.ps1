# Dump the full text of every dragon_penalty JSON from DS本体 + [龙之生存：] addons.
# ASCII-only on purpose (PowerShell 5.1 reads BOM-less scripts as ANSI).
Add-Type -AssemblyName System.IO.Compression.FileSystem

$mods = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'mods'

$jars = Get-ChildItem -LiteralPath $mods -File | Where-Object {
    $_.Name -like '*DragonSurvival-1.21.1*' -or
    $_.Name -like '*ds_aether_addon*' -or
    $_.Name -like '*tundradragon*' -or
    $_.Name -like '*frostfire_dragon*' -or
    $_.Name -like '*crystcursed_dragon*' -or
    $_.Name -like '*annihilator_type_a*' -or
    $_.Name -like '*astral_dragon*' -or
    $_.Name -like '*star_dragon*' -or
    $_.Name -like '*wing_kirin*' -or
    $_.Name -like '*ds_night_striker*'
}

foreach ($jar in $jars) {
    $zip = $null
    try { $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName) } catch { continue }

    $entries = $zip.Entries | Where-Object {
        $_.FullName -match '^data/[^/]+/dragonsurvival/dragon_penalty/[^/]+\.json$'
    } | Sort-Object FullName

    foreach ($e in $entries) {
        $reader = New-Object System.IO.StreamReader($e.Open())
        $text = $reader.ReadToEnd()
        $reader.Close()
        Write-Host "########## $($jar.Name)"
        Write-Host "########## $($e.FullName)"
        Write-Host $text
        Write-Host ""
    }

    if ($zip) { $zip.Dispose() }
}
