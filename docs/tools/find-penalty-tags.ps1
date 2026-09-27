# Find which dragon_penalty tags reference batophobia / source_emptiness across mod jars.
# ASCII-only (PowerShell 5.1 reads BOM-less scripts as ANSI).
Add-Type -AssemblyName System.IO.Compression.FileSystem

$mods = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'mods'
$targets = @('batophobia', 'source_emptiness')

$jars = Get-ChildItem -LiteralPath $mods -File | Where-Object { $_.Name -like '*.jar' }
Write-Host "Scanning $($jars.Count) jars for dragon_penalty tags referencing: $($targets -join ', ')"
Write-Host ""

foreach ($jar in $jars) {
    $zip = $null
    try { $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName) } catch { continue }

    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -notmatch 'dragon_penalty/.+\.json$') { continue }
        if ($entry.FullName -notmatch '/tags/') { continue }

        $reader = New-Object System.IO.StreamReader($entry.Open())
        $text = $reader.ReadToEnd()
        $reader.Close()

        foreach ($t in $targets) {
            if ($text -match [regex]::Escape($t)) {
                Write-Host "MATCH  [$t]"
                Write-Host "  jar   : $($jar.Name)"
                Write-Host "  entry : $($entry.FullName)"
                Write-Host "  body  : $($text -replace '\s+', ' ')"
                Write-Host ""
            }
        }
    }

    if ($zip) { $zip.Dispose() }
}
Write-Host "Done."
