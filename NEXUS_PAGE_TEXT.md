# Faster Kain

## Short Description

Makes normal Kain move as fast as wolf-form Kain in Blood Omen: Legacy of Kain.

## Description

Faster Kain is a tiny open-source patcher for the PC/GOG release of **Blood Omen: Legacy of Kain**.

It changes normal Kain's movement speed to match the wolf-form movement speed. In practical terms, normal Kain moves at `0x438`, the same value the game already uses for wolf Kain, instead of the original normal speed `0x21C`.

Because this uses an existing shipped movement speed rather than an arbitrary new value, it should in theory avoid breaking the game. Wolf-form Kain already moves at this speed in normal gameplay.

The mod also patches two speed-reset paths so the faster speed works immediately after loading, before you shapeshift.

## Features

- Normal Kain moves as fast as wolf-form Kain
- Works immediately on load; no shapeshift required
- Uses the game's existing wolf speed value
- Does not change shapeshift mana drain
- Does not include or redistribute `Kain.exe`
- Open-source PowerShell patcher
- Includes install, verify, and uninstall modes

## Requirements

- Blood Omen: Legacy of Kain PC/GOG release
- Windows PowerShell
- Close the game before installing or uninstalling

## Installation

1. Download and extract Faster Kain.
2. Put the `FasterKain` folder inside your Blood Omen install folder, next to `Kain.exe`.
3. Double-click `Install Faster Kain.bat`.

Manual PowerShell install:

```powershell
cd "C:\Program Files (x86)\GOG Galaxy\Games\Blood Omen\FasterKain"
powershell -ExecutionPolicy Bypass -File .\FasterKain.ps1 install
```

Custom game path:

```powershell
powershell -ExecutionPolicy Bypass -File .\FasterKain.ps1 install -GameDir "D:\Games\Blood Omen"
```

The patcher creates this backup next to `Kain.exe`:

```text
Kain.exe.faster-kain-backup
```

## Verify Installation

Double-click `Verify Faster Kain.bat`, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\FasterKain.ps1 verify
```

## Uninstall

Close the game, then run:

Double-click `Uninstall Faster Kain.bat`, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\FasterKain.ps1 uninstall
```

If the backup exists, the patcher restores it. If the backup is missing but `Kain.exe` exactly matches Faster Kain's installed bytes, the patcher reverses the patch directly.

## Compatibility Notes

This was made for the GOG/Verok PC release. If your `Kain.exe` does not match the expected byte patterns, the patcher will stop instead of applying an unsafe patch.

This may conflict with other mods that edit Kain movement speed or the same player speed reset routines.

## What Is Not Changed

- Shapeshift mana drain is unchanged
- Combat damage is unchanged
- Enemy speed is unchanged
- Save data is unchanged

## Permissions

This mod does not contain copyrighted game files. It is an open-source patcher released under the MIT License.
