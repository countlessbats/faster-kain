# Faster Kain

Faster Kain is a small executable patcher for the PC/GOG release of **Blood Omen: Legacy of Kain**.

It makes normal Kain — and mist form — move at the same speed as wolf-form Kain. The wolf speed is already a real, shipped game movement speed, so the patch should in theory avoid sequence breaks caused by values outside the game's normal range.

No game files are included. This mod patches your local `Kain.exe`.

## What It Changes

- Normal Kain movement speed: `0x21C` -> `0x438`
- Mist-form movement speed: `0x1A4` -> `0x438`
- Wolf-form Kain movement speed is already `0x438`
- Two reset paths are hooked so the faster speed works immediately on load, before shapeshifting
- Disguise form also moves at the boosted speed: it reuses normal Kain's default movement-speed value, which this patch already raises, so no separate edit is needed
- Bat form (the fast-travel form) has no walking speed of its own and is unaffected
- Mana drain is not changed

## Install

1. Close Blood Omen if it is running.
2. Copy the `FasterKain` folder into your Blood Omen install folder, next to `Kain.exe`.
3. Double-click `Install Faster Kain.bat`.

Or run this from PowerShell:

```powershell
cd "C:\Program Files (x86)\GOG Galaxy\Games\Blood Omen\FasterKain"
powershell -ExecutionPolicy Bypass -File .\FasterKain.ps1 install
```

If your game is somewhere else:

```powershell
powershell -ExecutionPolicy Bypass -File .\FasterKain.ps1 install -GameDir "D:\Games\Blood Omen"
```

The installer creates a backup named:

```text
Kain.exe.faster-kain-backup
```

## Verify

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

If the installer backup exists, uninstall restores it. If no backup exists but the executable exactly matches Faster Kain's installed patch bytes, the script reverses the patch byte-for-byte.

## Compatibility

Tested against the GOG/Verok PC release of Blood Omen. Other executables may not match the expected byte patterns; in that case, the patcher stops instead of guessing.

The mod should be compatible with anything that does not modify the same movement-speed constants or the two reset paths used by this patch.

## Source

The mod is the PowerShell patcher itself. It is intentionally small and readable so the exact byte changes can be audited.

## Build / Package From Source

No compiler is required. Faster Kain is a PowerShell patcher plus three batch-file wrappers.

To make a release zip from a fresh clone:

```powershell
git clone https://github.com/sevrlbats/faster-kain.git
cd faster-kain
Compress-Archive -Path .\* -DestinationPath ..\FasterKain-1.1.0.zip -Force
```

The generated zip is the distributable mod package. It should contain:

```text
FasterKain.ps1
Install Faster Kain.bat
Uninstall Faster Kain.bat
Verify Faster Kain.bat
README.md
NEXUS_PAGE_TEXT.md
CHANGELOG.md
LICENSE
```

Do not include `Kain.exe`, backups, save files, or any other Blood Omen game files in release packages.

## License

MIT License. See `LICENSE`.
