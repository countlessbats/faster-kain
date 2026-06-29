# Changelog

## 1.1.0

- Mist-form speed raised from its own slow drift `0x1A4` to wolf speed `0x438`, matching the normal-Kain boost
- Installer now upgrades an existing 1.0.0 install in place, applying only the new mist-form edit
- Backup is now written only when patching a fully unpatched `Kain.exe`, so it always represents a clean restore point
- Documented that disguise form already moves at the boosted speed (it shares normal Kain's default speed value); only bat, the fast-travel form, is unaffected

## 1.0.0

- Initial release
- Normal Kain speed changed from `0x21C` to wolf-form speed `0x438`
- Added reset-path hook so faster speed applies immediately after load
- Added install, verify, and uninstall patcher modes
- Added double-click batch files for install, verify, and uninstall
