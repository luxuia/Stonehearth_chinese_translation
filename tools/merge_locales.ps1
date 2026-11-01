<#
.SYNOPSIS
    Builds the localized files used by the chinese_translation mod.
.DESCRIPTION
    The base game translation ships with this patch. The Authorized Community
    Expansion (ACE) mod adds its own strings and points a number of base game
    keys at the ACE namespace. Those pointers and the ACE-only strings are read
    from the ACE version that is actually installed, so the patch keeps working
    when ACE is updated.
#>
param(
    [Parameter(Mandatory=$true)][string]$GameDir,
    [Parameter(Mandatory=$true)][string]$PayloadDir,
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'

function Read-Json([string]$Path) {
    $raw = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    return ($raw | ConvertFrom-Json)
}

function Write-Json($Obj, [string]$Path) {
    $json = $Obj | ConvertTo-Json -Depth 100
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $json, (New-Object Text.UTF8Encoding($false)))
}

# Add or replace a property on a PSCustomObject, keeping insertion order.
function Set-Prop($Obj, [string]$Name, $Value) {
    $p = $Obj.PSObject.Properties[$Name]
    if ($null -eq $p) {
        $Obj | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
    else {
        $Obj.PSObject.Properties[$Name].Value = $Value
    }
    return $Obj
}

# Deep merge; values from $Src win.
function Merge-Json($Dst, $Src) {
    foreach ($p in $Src.PSObject.Properties) {
        $cur = $Dst.PSObject.Properties[$p.Name]
        if ($null -ne $cur -and
            $null -ne $cur.Value -and
            ($cur.Value -is [pscustomobject]) -and
            ($p.Value -is [pscustomobject])) {
            Merge-Json $cur.Value $p.Value | Out-Null
        }
        else {
            Set-Prop $Dst $p.Name $p.Value | Out-Null
        }
    }
    return $Dst
}

# Add only the leaves that $Dst is missing; existing values are kept.
function Fill-Missing($Dst, $Src) {
    foreach ($p in $Src.PSObject.Properties) {
        $cur = $Dst.PSObject.Properties[$p.Name]
        if ($null -eq $cur) {
            Set-Prop $Dst $p.Name $p.Value | Out-Null
        }
        elseif (($cur.Value -is [pscustomobject]) -and ($p.Value -is [pscustomobject])) {
            Fill-Missing $cur.Value $p.Value | Out-Null
        }
    }
    return $Dst
}

# Flatten a JSON tree into 'dotted.key' -> value pairs.
function Flatten-Json($Obj, [string]$Prefix, [hashtable]$Acc) {
    foreach ($p in $Obj.PSObject.Properties) {
        $key = if ($Prefix) { "$Prefix.$($p.Name)" } else { $p.Name }
        if ($p.Value -is [pscustomobject]) { Flatten-Json $p.Value $key $Acc }
        else { $Acc[$key] = $p.Value }
    }
    return $Acc
}

# Rebuild a nested JSON tree from 'dotted.key' -> value pairs.
function Expand-Json([hashtable]$Flat) {
    $root = New-Object psobject
    foreach ($k in $Flat.Keys) {
        $parts = $k.Split('.')
        $cur = $root
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            $p = $cur.PSObject.Properties[$parts[$i]]
            if ($null -eq $p -or $p.Value -isnot [pscustomobject]) {
                Set-Prop $cur $parts[$i] (New-Object psobject) | Out-Null
            }
            $cur = $cur.PSObject.Properties[$parts[$i]].Value
        }
        Set-Prop $cur $parts[-1] $Flat[$k] | Out-Null
    }
    return $root
}

# Locate the ACE locale files. ACE may be a plain folder mod, a .smod archive or
# a Steam Workshop download, so all three are looked at.
function Find-AceLocales([string]$GameDir) {
    $direct = Join-Path $GameDir 'mods\stonehearth_ace\locales'
    if (Test-Path (Join-Path $direct 'locales_mixin.json')) { return $direct }

    $smod = Join-Path $GameDir 'mods\stonehearth_ace.smod'
    if (Test-Path $smod) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($smod)
        try {
            $entry = $zip.Entries | Where-Object { $_.FullName -eq 'stonehearth_ace/locales/locales_mixin.json' } | Select-Object -First 1
            if ($entry) {
                $tmp = Join-Path ([IO.Path]::GetTempPath()) ('ace_locales_' + [Guid]::NewGuid().ToString('N'))
                [IO.Directory]::CreateDirectory($tmp) | Out-Null
                foreach ($n in @('locales_mixin.json', 'en_mixin.json', 'zh-CN.json', 'en.json')) {
                    $e = $zip.Entries | Where-Object { $_.FullName -eq ('stonehearth_ace/locales/' + $n) } | Select-Object -First 1
                    if ($e) {
                        [IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $tmp $n), $true)
                    }
                }
                $zip.Dispose()
                return $tmp
            }
        }
        finally { $zip.Dispose() }
    }

    # Steam Workshop download.
    $workshop = Join-Path $GameDir 'workshop\content\253250'
    if (Test-Path $workshop) {
        foreach ($dir in (Get-ChildItem -Directory $workshop -ErrorAction SilentlyContinue)) {
            $candidate = Join-Path $dir.FullName 'stonehearth_ace\locales'
            if (Test-Path (Join-Path $candidate 'locales_mixin.json')) { return $candidate }
            $candidate2 = Join-Path $dir.FullName 'locales'
            if (Test-Path (Join-Path $candidate2 'locales_mixin.json')) { return $candidate2 }
        }
    }
    return $null
}

try {
    if (-not $OutDir) { $OutDir = Join-Path $GameDir 'mods\chinese_translation\locales' }

    # ------------------------------------------------------------ base game
    $out = Read-Json (Join-Path $PayloadDir 'translations\stonehearth\zh-CN.json')

    $aceLocales = Find-AceLocales $GameDir
    if ($aceLocales) {
        # Pointers: base game keys that must resolve inside the ACE namespace.
        $ptrFile = Join-Path $aceLocales 'locales_mixin.json'
        if (Test-Path $ptrFile) { Merge-Json $out (Read-Json $ptrFile) | Out-Null }

        # ACE-only strings. The 'mixins' key is a radiant chain directive rather
        # than a translatable string, so it must not end up in the file.
        #
        # These only fill in keys the shipped translation does not have. A few of
        # them exist in both places, and there the upstream Chinese is kept: ACE
        # merely reworded the English text, so its wording is no longer what the
        # translation was written against.
        $extraFile = Join-Path $aceLocales 'en_mixin.json'
        if (Test-Path $extraFile) {
            $extra = Read-Json $extraFile
            $m = $extra.PSObject.Properties['mixins']
            if ($null -ne $m) { $extra.PSObject.Properties.Remove('mixins') }
            Fill-Missing $out $extra | Out-Null
        }
    }

    # Strings upstream leaves untranslated.
    foreach ($fix in @(
        @('ui.game.citizens.workers_list_headers.morale', '士气'),
        @('ui.shell.select_roster.reembark_button', '重新出发')
    )) {
        $parts = $fix[0].Split('.')
        $cur = $out
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            $p = $cur.PSObject.Properties[$parts[$i]]
            if ($null -eq $p -or $p.Value -isnot [pscustomobject]) {
                Set-Prop $cur $parts[$i] (New-Object psobject) | Out-Null
            }
            $cur = $cur.PSObject.Properties[$parts[$i]].Value
        }
        Set-Prop $cur $parts[-1] $fix[1] | Out-Null
    }

    Write-Json $out (Join-Path $OutDir 'stonehearth_zh-CN.json')

    # ------------------------------------------------- ACE namespace fallbacks
    # The base game file above routes some keys into the ACE namespace. When the
    # installed ACE has no Chinese text for such a key the UI would show a raw
    # key, so the missing ones are supplied here and mixed into the ACE file.
    $aceZhPath = Join-Path $aceLocales 'zh-CN.json'
    if (Test-Path $aceZhPath) {
        $aceZhFlat = @{}
        Flatten-Json (Read-Json $aceZhPath) '' $aceZhFlat | Out-Null
        $outFlat = @{}
        Flatten-Json $out '' $outFlat | Out-Null

        $needed = @{}
        foreach ($k in $outFlat.Keys) {
            $v = $outFlat[$k]
            if ($v -is [string] -and $v.StartsWith('i18n(stonehearth_ace:')) {
                $target = $v.Substring('i18n(stonehearth_ace:'.Length).TrimEnd(')')
                if (-not $aceZhFlat.ContainsKey($target)) { $needed[$target] = $true }
            }
        }

        if ($needed.Count -gt 0) {
            $aceEnFlat = @{}
            $aceEnPath = Join-Path $aceLocales 'en.json'
            if (Test-Path $aceEnPath) {
                Flatten-Json (Read-Json $aceEnPath) '' $aceEnFlat | Out-Null
            }

            # Hand written translations for keys known to be missing.
            $manual = @{
                'ui.shell.select_roster.eye_color' = '眼睛颜色'
            }

            $extraFlat = @{}
            foreach ($t in $needed.Keys) {
                if ($manual.ContainsKey($t)) { $extraFlat[$t] = $manual[$t] }
                elseif ($aceEnFlat.ContainsKey($t)) { $extraFlat[$t] = $aceEnFlat[$t] }
            }

            if ($extraFlat.Count -gt 0) {
                Write-Json (Expand-Json $extraFlat) (Join-Path $OutDir 'ace_zh_extra.json')
                Write-Output ('ACE_EXTRA: ' + $extraFlat.Count)
            }
        }
    }

    # ------------------------------------------------------- other bundled mods
    # Any key the shipped translation lacks falls back to the English text so the
    # UI never shows a raw key. The English text lives inside the .smod archive.
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    foreach ($mod in @('rayyas_children', 'northern_alliance')) {
        $zh = Read-Json (Join-Path $PayloadDir ("translations\$mod\zh-CN.json"))

        $smod = Join-Path $GameDir ("mods\$mod.smod")
        if (Test-Path $smod) {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($smod)
            try {
                $entry = $zip.Entries | Where-Object { $_.FullName -eq "$mod/locales/en.json" } | Select-Object -First 1
                if ($null -ne $entry) {
                    $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
                    $enText = $reader.ReadToEnd()
                    $reader.Close()
                    $enFlat = @{}
                    Flatten-Json ($enText | ConvertFrom-Json) '' $enFlat | Out-Null
                    $zhFlat = @{}
                    Flatten-Json $zh '' $zhFlat | Out-Null
                    foreach ($k in $enFlat.Keys) {
                        if (-not $zhFlat.ContainsKey($k)) { $zhFlat[$k] = $enFlat[$k] }
                    }
                    $zh = Expand-Json $zhFlat
                }
            }
            finally { $zip.Dispose() }
        }

        Write-Json $zh (Join-Path $OutDir ("${mod}_zh-CN.json"))
    }

    Write-Output 'MERGE_OK'
    exit 0
}
catch {
    Write-Output ('MERGE_FAILED: ' + $_.Exception.Message)
    exit 1
}
