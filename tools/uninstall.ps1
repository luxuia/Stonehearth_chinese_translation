<#
.SYNOPSIS
    Removes the Chinese patch mods and sets the game language back to English.
#>
param(
    [string]$GameDir = $args[0]
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent $PSScriptRoot

function Fail([string]$Text) {
    Write-Output ''
    Write-Output "[x] $Text"
    exit 1
}

Write-Output ''
Write-Output '=============================================='
Write-Output '  卸载简体中文补丁'
Write-Output '=============================================='
Write-Output ''

if (-not $GameDir) {
    $GameDir = Read-Host '游戏目录'
}
if (-not $GameDir) { Fail '没有指定游戏目录。' }

$GameDir = $GameDir.Trim().Trim('"')
if ($GameDir.EndsWith('\')) { $GameDir = $GameDir.Substring(0, $GameDir.Length - 1) }
if (-not (Test-Path (Join-Path $GameDir 'Stonehearth.exe'))) { Fail "目录无效: $GameDir" }

foreach ($mod in @('chinese_translation', 'chinese_font')) {
    $dir = Join-Path $GameDir "mods\$mod"
    if (Test-Path $dir) {
        Write-Host "[1] 删除 $mod ..."
        Remove-Item -Recurse -Force $dir
    }
}

Write-Output '[2] 把语言改回英文 ...'
& (Join-Path $PSScriptRoot 'set_language.ps1') -GameDir $GameDir -Language 'en'
if ($LASTEXITCODE -ne 0) { Fail '修改 user_settings.json 失败。' }

Write-Output ''
Write-Output '完成。旧版补丁备份仍在:'
Write-Output (Join-Path $GameDir '_zh_patch_backup')
exit 0
