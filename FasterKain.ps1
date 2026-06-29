param(
    [ValidateSet("install", "uninstall", "verify")]
    [string]$Action = "install",

    [string]$GameDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$ExePath = Join-Path $GameDir "Kain.exe"
$BackupPath = Join-Path $GameDir "Kain.exe.faster-kain-backup"

function Convert-HexStringToBytes {
    param([string]$Hex)
    return [byte[]]($Hex -split "\s+" | Where-Object { $_ } | ForEach-Object { [Convert]::ToByte($_, 16) })
}

function Test-BytesAt {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [byte[]]$Expected
    )

    if ($Offset + $Expected.Length -gt $Data.Length) {
        return $false
    }

    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($Data[$Offset + $i] -ne $Expected[$i]) {
            return $false
        }
    }

    return $true
}

function Set-BytesAt {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [byte[]]$Bytes
    )

    for ($i = 0; $i -lt $Bytes.Length; $i++) {
        $Data[$Offset + $i] = $Bytes[$i]
    }
}

function Format-BytesAt {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [int]$Length
    )

    return (($Data[$Offset..($Offset + $Length - 1)] | ForEach-Object { $_.ToString("X2") }) -join " ")
}

# Normal-Kain walk speed: 0x21C immediates raised to the shipped wolf speed 0x438.
$SpeedOffsets = @(0x1FFC, 0x615A, 0x6291, 0x8859, 0x393C0, 0x3A57B)
$SpeedOld = Convert-HexStringToBytes "1C 02 00 00"
$SpeedNew = Convert-HexStringToBytes "38 04 00 00"

# Two speed-reset paths, redirected to the code cave so the boost applies before shapeshifting.
$Hook1Offset = 0x1F5E9
$Hook1Old = Convert-HexStringToBytes "8B 90 9C 00 00 00 89 50 0C"
$Hook1New = Convert-HexStringToBytes "E9 E4 A8 02 00 90 90 90 90"

$Hook2Offset = 0x23445
$Hook2Old = Convert-HexStringToBytes "8B 98 9C 00 00 00 89 58 0C"
$Hook2New = Convert-HexStringToBytes "E9 A3 6A 02 00 90 90 90 90"

$CaveOffset = 0x49ED2
$CaveOld = Convert-HexStringToBytes ("00 " * 56)
$CaveNew = Convert-HexStringToBytes @"
80 78 7C 05 72 08 8B 90 9C 00 00 00 EB 05 BA 38
04 00 00 89 50 0C E9 05 57 FD FF 80 78 7C 05 72
08 8B 98 9C 00 00 00 EB 05 BB 38 04 00 00 89 58
0C 31 DB E9 46 95 FD FF
"@

# Mist-form (shapeshift form 6) walk speed: its own slow drift 0x1A4 raised to wolf speed 0x438.
# This is the immediate of "mov dword ptr [ebx+0xC], 0x1A4" in the per-form speed handler at
# VA 0x448E3F; the next two instructions copy it into the base-speed field, so one immediate
# covers both the current and stored speed for mist.
$MistSpeedOffset = 0x39442
$MistSpeedOld = Convert-HexStringToBytes "A4 01 00 00"
$MistSpeedNew = $SpeedNew

# All independent byte edits this patch makes, as (Name, Offset, Old, New) units.
$Patches = @()
foreach ($offset in $SpeedOffsets) {
    $Patches += @{ Name = "normal speed const 0x$($offset.ToString('X'))"; Offset = $offset; Old = $SpeedOld; New = $SpeedNew }
}
$Patches += @{ Name = "reset hook 1"; Offset = $Hook1Offset; Old = $Hook1Old; New = $Hook1New }
$Patches += @{ Name = "reset hook 2"; Offset = $Hook2Offset; Old = $Hook2Old; New = $Hook2New }
$Patches += @{ Name = "code cave"; Offset = $CaveOffset; Old = $CaveOld; New = $CaveNew }
$Patches += @{ Name = "mist-form speed"; Offset = $MistSpeedOffset; Old = $MistSpeedOld; New = $MistSpeedNew }

if (!(Test-Path -LiteralPath $ExePath)) {
    throw "Could not find Kain.exe at: $ExePath"
}

$Data = [IO.File]::ReadAllBytes($ExePath)

function Test-Installed {
    foreach ($p in $Patches) {
        if (!(Test-BytesAt $Data $p.Offset $p.New)) {
            return $false
        }
    }

    return $true
}

function Test-Uninstalled {
    foreach ($p in $Patches) {
        if (!(Test-BytesAt $Data $p.Offset $p.Old)) {
            return $false
        }
    }

    return $true
}

# Every unit must be recognizably old or new, or we refuse to touch the file.
# This also lets the patcher upgrade an older Faster Kain install by applying only
# the units that are still at their original bytes (for example, mist-form speed).
function Test-AllUnitsKnown {
    foreach ($p in $Patches) {
        if (!((Test-BytesAt $Data $p.Offset $p.Old) -or (Test-BytesAt $Data $p.Offset $p.New))) {
            return $false
        }
    }

    return $true
}

if ($Action -eq "verify") {
    if (Test-Installed) {
        Write-Host "Faster Kain is installed."
        exit 0
    }

    if (Test-Uninstalled) {
        Write-Host "Faster Kain is not installed. Kain.exe matches the expected unpatched byte patterns."
        exit 0
    }

    Write-Host "Kain.exe does not match the expected installed or uninstalled byte patterns."
    Write-Host "This may be a different game version, another mod, or a partial/manual patch."
    exit 1
}

if ($Action -eq "install") {
    if (Test-Installed) {
        Write-Host "Faster Kain is already installed."
        exit 0
    }

    foreach ($p in $Patches) {
        if (!((Test-BytesAt $Data $p.Offset $p.Old) -or (Test-BytesAt $Data $p.Offset $p.New))) {
            throw "Unexpected bytes for $($p.Name) at 0x$($p.Offset.ToString("X")). Found: $(Format-BytesAt $Data $p.Offset $p.Old.Length)"
        }
    }

    # Only snapshot a backup when the executable is fully unpatched, so the backup
    # always represents a clean, restorable Kain.exe.
    if (!(Test-Path -LiteralPath $BackupPath) -and (Test-Uninstalled)) {
        Copy-Item -LiteralPath $ExePath -Destination $BackupPath
    }

    $applied = 0
    foreach ($p in $Patches) {
        if (Test-BytesAt $Data $p.Offset $p.Old) {
            Set-BytesAt $Data $p.Offset $p.New
            $applied++
        }
    }

    [IO.File]::WriteAllBytes($ExePath, $Data)
    Write-Host "Installed Faster Kain ($applied of $($Patches.Count) byte units applied; the rest were already patched)."
    if (Test-Path -LiteralPath $BackupPath) {
        Write-Host "Backup: $BackupPath"
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if (Test-Uninstalled) {
        Write-Host "Faster Kain is already uninstalled."
        exit 0
    }

    if (Test-Path -LiteralPath $BackupPath) {
        Copy-Item -LiteralPath $BackupPath -Destination $ExePath -Force
        Write-Host "Uninstalled Faster Kain by restoring backup: $BackupPath"
        exit 0
    }

    if (!(Test-AllUnitsKnown)) {
        throw "Cannot safely uninstall: no backup was found and Kain.exe does not match Faster Kain's expected byte patterns."
    }

    foreach ($p in $Patches) {
        if (Test-BytesAt $Data $p.Offset $p.New) {
            Set-BytesAt $Data $p.Offset $p.Old
        }
    }

    [IO.File]::WriteAllBytes($ExePath, $Data)
    Write-Host "Uninstalled Faster Kain by reversing the patch bytes."
    exit 0
}
