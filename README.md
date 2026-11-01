# Stonehearth 简体中文补丁 / Stonehearth Simplified Chinese Patch

一键给 Stonehearth 装上简体中文界面，并把游戏语言切到中文。

A one-click installer that adds a Simplified Chinese interface to Stonehearth and switches the game language to `zh-CN`.

---

## 使用方法 / Usage

1. 下载并解压本仓库（或 Release 里的 zip）。
   Download and unzip the repository (or a release build).
2. 双击 **`install.bat`**。
   Double-click **`install.bat`**.
3. 输入或粘贴 Stonehearth 的安装目录（含有 `Stonehearth.exe` 的文件夹），回车。
   Enter the Stonehearth installation folder (the one containing `Stonehearth.exe`).
4. 装完可以直接启动游戏。
   The installer can launch the game for you when it finishes.

> 也可以把游戏目录直接拖到 `install.bat` 上，省去输入：
> You can also drag the game folder onto `install.bat` to skip the prompt:
>
> ```
> install.bat "D:\Games\Stonehearth"
> ```

语言切换：**设置 → 系统 → 语言 → 简体中文**。
Switch language in game: **Settings → System → Language → 简体中文**.

---

## 它做了什么 / What it does

安装器会在游戏的 `mods` 目录下写入两个普通文件夹模组：

The installer writes two plain-folder mods into the game's `mods` directory:

| 模组 / Mod | 命名空间 / Namespace | 作用 / Purpose |
| --- | --- | --- |
| `chinese_translation` | `chinese_translation` | 基础游戏、Rayya's Children、Northern Alliance、ACE 的中文文本 |
| `chinese_font` | `chinese_font` | 把 AutourOne 与 GROBOLD 字体换成中文字型，界面才不会显示方块 |

翻译文本来自上游仓库 [`law/chinese_translation`](https://github.com/luxuia/chinese_translation) 所维护的 r949 版本翻译。

The translation data comes from the r949 translations maintained upstream in [`law/chinese_translation`](https://github.com/luxuia/chinese_translation).

### 关于 ACE / About ACE

如果 **Authorized Community Expansion** 已安装（普通文件夹模组、`.smod` 压缩包或 Steam 创意工坊下载都能识别），安装器会读取**你本机已安装的** ACE 语言文件，把 ACE 的字符串与指针合并进来，而不是套用上游那份旧翻译 —— 这样 ACE 界面也是中文，且不会丢掉新版 ACE 的内容。

If **Authorized Community Expansion** is installed (as a folder mod, a `.smod` archive or a Steam Workshop download — all three are detected), the installer reads the ACE locale files **from your own installation** and merges them in, so ACE screens are translated too and no newer ACE content is lost.

没有装 ACE 也能正常安装，只是不会出现 ACE 相关的中文。
The patch installs fine without ACE; only the ACE-specific text is then absent.

### 旧版补丁 / Legacy patch

2016 年那版 `Chinese Translation.smod`（Early Access 时代）会覆盖同样的语言文件，与本补丁冲突。安装器会把它**移到** `_zh_patch_backup`（不删除），不影响你回退。

The 2016 `Chinese Translation.smod` overrides the same locale files and conflicts with this patch. The installer **moves** it to `_zh_patch_backup` (never deletes it) so you can always get it back.

---

## 手动安装 / Manual install

不想用脚本的话，直接复制文件即可：

If you prefer to do it by hand, just copy the files:

```
mods/
├── chinese_translation/
│   ├── manifest.json              <- manifests/chinese_translation.json
│   ├── added_languages.json       <- payload/added_languages.json
│   └── locales/
│       ├── stonehearth_zh-CN.json
│       ├── rayyas_children_zh-CN.json
│       ├── northern_alliance_zh-CN.json
│       └── ace_zh_extra.json
└── chinese_font/
    ├── manifest.json              <- manifests/chinese_font.json
    └── fonts/
        ├── autourone/zh-CN.ttf, zh-CN.woff
        └── grobold/zh-CN.ttf, zh-CN.woff
```

`stonehearth_zh-CN.json` 需要根据本机 ACE 版本生成，所以建议还是用 `install.bat`；若不装 ACE，可直接用 `payload/translations/stonehearth/zh-CN.json`。

`stonehearth_zh-CN.json` is generated from the ACE version you have, so using `install.bat` is recommended. Without ACE you can just copy `payload/translations/stonehearth/zh-CN.json`.

最后把 `user_settings.json` 里的 `"language"` 改成 `"zh-CN"`。
Finally set `"language"` to `"zh-CN"` in `user_settings.json`.

---

## 卸载 / Uninstall

运行 `uninstall.bat`，或手动删除 `mods/chinese_translation` 与 `mods/chinese_font`，并把 `user_settings.json` 的 `"language"` 改回 `"en"`。

Run `uninstall.bat`, or delete `mods/chinese_translation` and `mods/chinese_font` manually and set `"language"` back to `"en"` in `user_settings.json`.

---

## 兼容性 / Compatibility

* 目标版本：Stonehearth **1.1.0.949** (r949)。
  Target version: Stonehearth **1.1.0.949** (r949).
* 需要 Windows PowerShell 5 或更高版本（Windows 自带）。
  Requires Windows PowerShell 5 or newer (ships with Windows).
* 支持 Steam 版与非 Steam 打包版。
  Works with both Steam and non-Steam (repacked) copies.

---

## 致谢 / Credits

* 翻译 / Translations: [`law/chinese_translation`](https://github.com/luxuia/chinese_translation)
* 字体 / Fonts: Tensentype JiaLiZhongHeiJ, CloudRuiHeiGBK
