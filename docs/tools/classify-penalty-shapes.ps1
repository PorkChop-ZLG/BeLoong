# Classify every penalty's top-level condition by shape.
# ASCII-only on purpose (PowerShell 5.1 reads BOM-less scripts as ANSI).
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Dir  = Join-Path $Root 'kubejs\data'

$rows = @()

Get-ChildItem -LiteralPath $Dir -Recurse -File -Filter *.json |
    Where-Object { $_.FullName -match 'dragon_penalty' -and $_.FullName -notmatch '\\tags\\' } |
    Sort-Object FullName |
    ForEach-Object {
        $json = Get-Content -LiteralPath $_.FullName -Raw
        try { $j = $json | ConvertFrom-Json } catch { return }

        $top = if ($j.condition) { $j.condition.condition } else { '(none)' }

        # depth of the palace term
        $depth = if ($json -match 'loong_palace') { 'yes' } else { 'no' }

        # figure out the chain shape
        $shape = ''
        if ($top -eq '(none)') {
            $shape = if ($depth -eq 'yes') { 'STANDALONE-LOCATIONCHECK' } else { 'NO-CONDITION' }
        }
        elseif ($top -eq 'minecraft:inverted') {
            $inner = $j.condition.term.condition
            if ($inner -eq 'minecraft:any_of') { $shape = 'inverted -> any_of' }
            elseif ($inner -eq 'minecraft:all_of') { $shape = 'inverted -> all_of' }
            else { $shape = "inverted -> $inner" }
        }
        elseif ($top -eq 'minecraft:all_of') { $shape = 'all_of' }
        elseif ($top -eq 'minecraft:any_of') { $shape = 'any_of' }
        else { $shape = $top }

        # where did we put the palace term?
        $slot = '-'
        if ($depth -eq 'yes') {
            if ($top -eq 'minecraft:all_of') { $slot = 'all_of.terms[0]' }
            elseif ($top -eq 'minecraft:inverted' -and $j.condition.term.condition -eq 'minecraft:any_of') { $slot = 'inverted.any_of.terms[0]' }
            elseif ($top -eq 'minecraft:inverted' -and $j.condition.term.condition -eq 'minecraft:location_check') { $slot = 'inverted.term' }
            elseif ($top -eq 'minecraft:inverted' -and $j.condition.term.condition -eq 'minecraft:all_of') { $slot = 'inverted.all_of.terms[0]' }
            else { $slot = '?' }
        }

        $rows += [pscustomobject]@{
            File   = $_.Name
            Top    = $top
            Shape  = $shape
            Palace = $depth
            Slot   = $slot
        }
    }

Write-Host "=== ALL PENALTIES: top-level condition shape ==="
$rows | Format-Table File, Shape, Palace, Slot -AutoSize | Out-String -Width 200

Write-Host ""
Write-Host "=== GROUPED BY PALACE-TERM LOCATION ==="
$rows | Group-Object Slot | Sort-Object Name | ForEach-Object {
    Write-Host "[$($_.Name)]  count=$($_.Count)"
    $_.Group | ForEach-Object { Write-Host "    $($_.File)   ($($_.Shape))" }
}

Write-Host ""
Write-Host "=== any_of 出现在链条中的文件 ==="
$rows | Where-Object { $_.Shape -match 'any_of' } | ForEach-Object { Write-Host "  $($_.File)" }
Write-Host ""
Write-Host "=== all_of 出现在链条中的文件 ==="
$rows | Where-Object { $_.Shape -match 'all_of' } | ForEach-Object { Write-Host "  $($_.File)" }
