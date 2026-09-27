# Map every dragon_penalty id to the species tags that reference it, across all mod jars.
# ASCII-only on purpose (PowerShell 5.1 reads BOM-less scripts as ANSI).
Add-Type -AssemblyName System.IO.Compression.FileSystem

$mods = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'mods'
$jars = Get-ChildItem -LiteralPath $mods -File | Where-Object { $_.Name -like '*.jar' }

# Collect all penalty ids defined anywhere
$penalties = @{}
# Collect tag -> values
$tags = @{}

foreach ($jar in $jars) {
    $zip = $null
    try { $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName) } catch { continue }

    foreach ($e in $zip.Entries) {
        if ($e.FullName -match '^data/([^/]+)/dragonsurvival/dragon_penalty/([^/]+)\.json$') {
            $ns = $Matches[1]; $id = $Matches[2]
            $penalties["$ns`:$id"] = $jar.Name
        }
        elseif ($e.FullName -match '^data/([^/]+)/tags/dragonsurvival/dragon_penalty/([^/]+)\.json$') {
            $ns = $Matches[1]; $tag = $Matches[2]
            $reader = New-Object System.IO.StreamReader($e.Open())
            $text = $reader.ReadToEnd()
            $reader.Close()
            try {
                $j = $text | ConvertFrom-Json
                $vals = @()
                if ($j.values) { $vals = @($j.values) }
                $tags["$ns`:$tag"] = @{ jar = $jar.Name; values = $vals }
            } catch {
                $tags["$ns`:$tag"] = @{ jar = $jar.Name; values = @('(PARSE FAIL)') }
            }
        }
    }
    if ($zip) { $zip.Dispose() }
}

Write-Host "=== All penalty definitions ($($penalties.Count)) ==="
$penalties.Keys | Sort-Object | ForEach-Object { "  $_    [$($penalties[$_])]" }

Write-Host ""
Write-Host "=== All penalty tags and their members ==="
foreach ($k in ($tags.Keys | Sort-Object)) {
    Write-Host "  $k   [$($tags[$k].jar)]"
    foreach ($v in $tags[$k].values) { Write-Host "      - $v" }
}

Write-Host ""
Write-Host "=== Reference count per penalty ==="
foreach ($p in ($penalties.Keys | Sort-Object)) {
    $refs = @()
    foreach ($k in $tags.Keys) {
        if ($tags[$k].values -contains $p) { $refs += $k }
    }
    $status = if ($refs.Count -eq 0) { 'UNREFERENCED' } else { ($refs -join ', ') }
    "{0,-55} {1}" -f $p, $status
}
