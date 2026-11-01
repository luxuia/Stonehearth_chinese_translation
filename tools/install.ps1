<#
.SYNOPSIS
    Installs the Simplified Chinese patch into a Stonehearth installation.
.DESCRIPTION
    Asks for the game folder, writes the chinese_translation and chinese_font
    mods into it, regenerates the localized files against the ACE version that
    is installed and switches the game language to zh-CN.
#>
param(
    [string]$GameDir = $args[0]
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent $PSScriptRoot
$PayloadDir = Join-Path $Root 'payload'

function Say([string]$Text) { Write-Output $Text }
function Fail([string]$Text) {
    Write-Output ''
    Write-Output "[x] $Text"
    exit 1
}

Say ''
Say '=============================================='
Say '  Stonehearth 简体中文补丁安装程序'
Say '=============================================='
Say ''

if (-not (Test-Path (Join-Path $PayloadDir 'translations\stonehearth\zh-CN.json'))) {
    Fail "找不到补丁数据: $PayloadDir`n请在解压出来的仓库文件夹里运行 install.bat。"
}

# ------------------------------------------------------------ pick the folder
if (-not $GameDir) {
    Say '请选择 Stonehearth 的安装目录（含有 Stonehearth.exe 的文件夹）:'
    Say ''
    $GameDir = Read-Host '游戏目录'
}
if (-not $GameDir) { Fail '没有指定游戏目录。' }

$GameDir = $GameDir.Trim().Trim('"')
if ($GameDir.EndsWith('\')) { $GameDir = $GameDir.Substring(0, $GameDir.Length - 1) }

if (-not (Test-Path (Join-Path $GameDir 'Stonehearth.exe'))) {
    Fail "目录无效: $GameDir`n里面没有找到 Stonehearth.exe。"
}
if (-not (Test-Path (Join-Path $GameDir 'mods'))) {
    Fail "目录无效: $GameDir`n里面没有找到 mods 文件夹。"
}
Say "游戏目录: $GameDir"
Say ''

$ModsDir = Join-Path $GameDir 'mods'
$BackupDir = Join-Path $GameDir '_zh_patch_backup'

# --------------------------------------------------------------- back things up
# The 2016 A16 era "Chinese Translation.smod" overrides the very same locale
# files and would conflict with this patch. Move it aside, never delete it.
$legacy = Join-Path $ModsDir 'Chinese Translation.smod'
if (Test-Path $legacy) {
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    Say '[1] 发现旧版 Chinese Translation.smod（2016 年版本），正在备份...'
    Move-Item -Force $legacy (Join-Path $BackupDir 'Chinese Translation.smod')
    Say "    已备份到: $BackupDir"
}

# Loose folder mods with the same name shadow the .smod files and never load.
foreach ($name in @('stonehearth', 'northern_alliance', 'rayyas_children')) {
    $dir = Join-Path $ModsDir $name
    if (Test-Path (Join-Path $dir 'manifest.json')) {
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
        Say "[1] 备份无效的同名文件夹模组: $name"
        $dest = Join-Path $BackupDir $name
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        Move-Item -Force $dir $dest
    }
}

# ------------------------------------------------------------ install the mods
$ctDir = Join-Path $ModsDir 'chinese_translation'
$ctLocales = Join-Path $ctDir 'locales'
$cfDir = Join-Path $ModsDir 'chinese_font'
foreach ($d in @($ctDir, $ctLocales, (Join-Path $cfDir 'fonts\autourone'), (Join-Path $cfDir 'fonts\grobold'))) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Copy-Item -Force (Join-Path $Root 'manifests\chinese_translation.json') (Join-Path $ctDir 'manifest.json')
Copy-Item -Force (Join-Path $Root 'manifests\chinese_font.json')        (Join-Path $cfDir 'manifest.json')
Copy-Item -Force (Join-Path $PayloadDir 'added_languages.json')        (Join-Path $ctDir 'added_languages.json')

foreach ($fam in @('autourone', 'grobold')) {
    foreach ($ext in @('ttf', 'woff')) {
        Copy-Item -Force (Join-Path $PayloadDir "fonts\$fam\zh-CN.$ext") (Join-Path $cfDir "fonts\$fam\zh-CN.$ext")
    }
}
Say '[2] 模组文件已复制，正在生成中文翻译...'

$mergeOut = & (Join-Path $PSScriptRoot 'merge_locales.ps1') -GameDir $GameDir -PayloadDir $PayloadDir -OutDir $ctLocales
foreach ($line in $mergeOut) { Say "    $line" }
if ($LASTEXITCODE -ne 0) { Fail '生成中文翻译文件失败。' }

Say '[3] 正在把游戏语言切换为简体中文...'
$langOut = & (Join-Path $PSScriptRoot 'set_language.ps1') -GameDir $GameDir -Language 'zh-CN' -Mods 'chinese_translation,chinese_font'
foreach ($line in $langOut) { Say "    $line" }
if ($LASTEXITCODE -ne 0) { Fail '修改 user_settings.json 失败。' }

Say ''
Say '=============================================='
Say '  安装完成'
Say '=============================================='
Say ''
Say '现在可以直接启动游戏了。'
Say '语言: 设置 -> 系统 -> 语言 -> 简体中文'
Say ''
if (Test-Path $BackupDir) { Say "旧版补丁备份: $BackupDir" }

$answer = ''
try { $answer = Read-Host '要现在启动游戏吗? [Y=是 N=否]' } catch { $answer = '' }
if ($answer -match '^[Yy]') {
    Start-Process -FilePath (Join-Path $GameDir 'Stonehearth.exe')
    Say '游戏已启动。'
}
exit 0
