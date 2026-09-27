# 读取存档 playerdata(.dat, gzip+NBT)，导出龙之生存相关数据：
#   物种 / 成长值 / 每个技能的 level
# 用法: pwsh -File read-playerdata-nbt.ps1 -Path '<playerdata.dat>'
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Filter = 'dragon|growth|abilit|magic|species|stage'
)

$ErrorActionPreference = 'Stop'

# ---------- 读取并 gunzip ----------
$raw = [System.IO.File]::ReadAllBytes($Path)
$ms  = New-Object System.IO.MemoryStream(,$raw)
if ($raw[0] -eq 0x1F -and $raw[1] -eq 0x8B) {
    $gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $out = New-Object System.IO.MemoryStream
    $gz.CopyTo($out); $gz.Dispose()
    $b = $out.ToArray()
} else {
    $b = $raw
}

$script:pos = 0
function Read-U8 { $v = $script:b[$script:pos]; $script:pos += 1; return $v }
# NBT 数值是大端，BitConverter 是小端 —— 先反转字节再转换，避免溢出
function Read-I16 {
    $a = [byte[]]@($script:b[$script:pos+1], $script:b[$script:pos]); $script:pos += 2
    return [System.BitConverter]::ToInt16($a, 0)
}
function Read-I32 {
    $a = [byte[]]@($script:b[$script:pos+3], $script:b[$script:pos+2], $script:b[$script:pos+1], $script:b[$script:pos])
    $script:pos += 4
    return [System.BitConverter]::ToInt32($a, 0)
}
function Read-I64 {
    $a = [byte[]]@($script:b[$script:pos+7], $script:b[$script:pos+6], $script:b[$script:pos+5], $script:b[$script:pos+4],
                   $script:b[$script:pos+3], $script:b[$script:pos+2], $script:b[$script:pos+1], $script:b[$script:pos])
    $script:pos += 8
    return [System.BitConverter]::ToInt64($a, 0)
}
function Read-F32 {
    $a = [byte[]]@($script:b[$script:pos+3], $script:b[$script:pos+2], $script:b[$script:pos+1], $script:b[$script:pos])
    $script:pos += 4
    return [System.BitConverter]::ToSingle($a, 0)
}
function Read-F64 {
    $a = [byte[]]@($script:b[$script:pos+7], $script:b[$script:pos+6], $script:b[$script:pos+5], $script:b[$script:pos+4],
                   $script:b[$script:pos+3], $script:b[$script:pos+2], $script:b[$script:pos+1], $script:b[$script:pos])
    $script:pos += 8
    return [System.BitConverter]::ToDouble($a, 0)
}
function Read-Str {
    $len = Read-I16
    $s = [System.Text.Encoding]::UTF8.GetString($script:b, $script:pos, $len)
    $script:pos += $len
    return $s
}

function Read-Payload([int]$type) {
    switch ($type) {
        1  { return [int]([sbyte](Read-U8)) }
        2  { return Read-I16 }
        3  { return Read-I32 }
        4  { return Read-I64 }
        5  { return Read-F32 }
        6  { return Read-F64 }
        7  { $n = Read-I32; $script:pos += $n; return "<byte[$n]>" }
        8  { return Read-Str }
        9  {
            $et = Read-U8; $n = Read-I32
            $items = @()
            for ($i = 0; $i -lt $n; $i++) { $items += ,(Read-Payload $et) }
            return ,$items
        }
        10 {
            $h = [ordered]@{}
            while ($true) {
                $t = Read-U8
                if ($t -eq 0) { break }
                $name = Read-Str
                $h[$name] = Read-Payload $t
            }
            return $h
        }
        11 { $n = Read-I32; $a = @(); for ($i=0;$i -lt $n;$i++){ $a += Read-I32 }; return ,$a }
        12 { $n = Read-I32; $a = @(); for ($i=0;$i -lt $n;$i++){ $a += Read-I64 }; return ,$a }
        default { throw "未知 tag 类型 $type @ $script:pos" }
    }
}

# ---------- 解析根节点 ----------
$rootType = Read-U8
$rootName = Read-Str
$root = Read-Payload $rootType
Write-Output "根节点: $rootName (type=$rootType), 解压后 $($b.Length) 字节"
Write-Output ""

# ---------- 遍历输出 ----------
$script:rows = New-Object System.Collections.ArrayList
function Walk($node, [string]$path) {
    if ($node -is [System.Collections.IDictionary]) {
        foreach ($k in $node.Keys) {
            $v = $node[$k]
            $p = if ($path) { "$path.$k" } else { "$k" }
            if ($v -is [System.Collections.IDictionary] -or ($v -is [System.Collections.IEnumerable] -and $v -isnot [string])) {
                Walk $v $p
            } else {
                $script:rows.Add([pscustomobject]@{ Path = $p; Value = "$v" }) | Out-Null
            }
        }
    } elseif ($node -is [System.Collections.IEnumerable] -and $node -isnot [string]) {
        $i = 0
        foreach ($e in $node) {
            if ($e -is [System.Collections.IDictionary] -or ($e -is [System.Collections.IEnumerable] -and $e -isnot [string])) {
                Walk $e "$path[$i]"
            } else {
                $script:rows.Add([pscustomobject]@{ Path = "$path[$i]"; Value = "$e" }) | Out-Null
            }
            $i++
        }
    }
}
Walk $root ''

Write-Output "=== 匹配 /$Filter/ 的叶子节点 ==="
$script:rows | Where-Object { $_.Path -match $Filter } | ForEach-Object {
    Write-Output ("  {0,-72} = {1}" -f $_.Path, $_.Value)
}
