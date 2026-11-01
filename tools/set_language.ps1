<#
.SYNOPSIS
    Switches the game to the requested language and enables the given mods.
.DESCRIPTION
    The game keeps its settings in user_settings.json in the game folder. The
    'language' key selects the UI language; the 'mods' section records whether
    a mod is enabled.

    Different radiant builds look the enable flag up either by the mod's
    namespace or by its display name, so both spellings are written.
#>
param(
    [Parameter(Mandatory=$true)][string]$GameDir,
    [string]$Language = 'zh-CN',
    [string]$Mods = '',
    [string]$ManifestDir
)

$ErrorActionPreference = 'Stop'

try {
    if (-not $ManifestDir -or -not (Test-Path $ManifestDir)) {
        $ManifestDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'manifests'
    }

    $settingsPath = Join-Path $GameDir 'user_settings.json'

    if (Test-Path $settingsPath) {
        $raw = [IO.File]::ReadAllText($settingsPath, [Text.Encoding]::UTF8)
        $settings = $raw | ConvertFrom-Json
    }
    else {
        $settings = New-Object psobject
    }

    function Set-Prop($Obj, [string]$Name, $Value) {
        $p = $Obj.PSObject.Properties[$Name]
        if ($null -eq $p) { $Obj | Add-Member -MemberType NoteProperty -Name $Name -Value $Value }
        else { $Obj.PSObject.Properties[$Name].Value = $Value }
        return $Obj
    }

    # --- language --------------------------------------------------------
    Set-Prop $settings 'language' $Language | Out-Null

    # --- mod enable flags ------------------------------------------------
    $modsProp = $settings.PSObject.Properties['mods']
    if ($null -eq $modsProp) {
        Set-Prop $settings 'mods' (New-Object psobject) | Out-Null
        $modsProp = $settings.PSObject.Properties['mods']
    }
    $dirProp = $modsProp.Value.PSObject.Properties['directory']
    if ($null -eq $dirProp) {
        Set-Prop $modsProp.Value 'directory' (New-Object psobject) | Out-Null
        $dirProp = $modsProp.Value.PSObject.Properties['directory']
    }
    $dir = $dirProp.Value

    foreach ($mod in ($Mods -split ',' | Where-Object { $_ })) {
        $mod = $mod.Trim()
        # A mod may be known by its namespace, by the display name in its
        # manifest, or by its folder name. Write all of them.
        $keys = @($mod)
        $manifest = Join-Path $ManifestDir "$mod.json"
        if (Test-Path $manifest) {
            $info = (([IO.File]::ReadAllText($manifest, [Text.Encoding]::UTF8)) | ConvertFrom-Json).info
            if ($info.PSObject.Properties['namespace']) { $keys += $info.namespace }
            if ($info.PSObject.Properties['name']) { $keys += $info.name }
        }

        foreach ($key in ($keys | Select-Object -Unique)) {
            $entry = $dir.PSObject.Properties[$key]
            if ($null -eq $entry) {
                Set-Prop $dir $key (New-Object psobject) | Out-Null
                $entry = $dir.PSObject.Properties[$key]
            }
            Set-Prop $entry.Value 'enabled' $true | Out-Null
        }
    }

    # --- write it back ----------------------------------------------------
    $json = $settings | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($settingsPath, $json, (New-Object Text.UTF8Encoding($false)))

    Write-Output "LANGUAGE_SET: $Language"
    exit 0
}
catch {
    Write-Output ('LANGUAGE_FAILED: ' + $_.Exception.Message)
    exit 1
}
