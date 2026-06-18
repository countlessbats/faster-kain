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

$SpeedOffsets = @(0x1FFC, 0x615A, 0x6291, 0x8859, 0x393C0, 0x3A57B)
$SpeedOld = Convert-HexStringToBytes "1C 02 00 00"
$SpeedNew = Convert-HexStringToBytes "38 04 00 00"

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

if (!(Test-Path -LiteralPath $ExePath)) {
    throw "Could not find Kain.exe at: $ExePath"
}

$Data = [IO.File]::ReadAllBytes($ExePath)

function Test-Installed {
    foreach ($offset in $SpeedOffsets) {
        if (!(Test-BytesAt $Data $offset $SpeedNew)) {
            return $false
        }
    }

    return (
        (Test-BytesAt $Data $Hook1Offset $Hook1New) -and
        (Test-BytesAt $Data $Hook2Offset $Hook2New) -and
        (Test-BytesAt $Data $CaveOffset $CaveNew)
    )
}

function Test-Uninstalled {
    foreach ($offset in $SpeedOffsets) {
        if (!(Test-BytesAt $Data $offset $SpeedOld)) {
            return $false
        }
    }

    return (
        (Test-BytesAt $Data $Hook1Offset $Hook1Old) -and
        (Test-BytesAt $Data $Hook2Offset $Hook2Old) -and
        (Test-BytesAt $Data $CaveOffset $CaveOld)
    )
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

    foreach ($offset in $SpeedOffsets) {
        if (!(Test-BytesAt $Data $offset $SpeedOld)) {
            throw "Unexpected bytes at 0x$($offset.ToString("X")). Found: $(Format-BytesAt $Data $offset 4)"
        }
    }

    if (!(Test-BytesAt $Data $Hook1Offset $Hook1Old)) {
        throw "Unexpected bytes at hook site 1. Found: $(Format-BytesAt $Data $Hook1Offset $Hook1Old.Length)"
    }

    if (!(Test-BytesAt $Data $Hook2Offset $Hook2Old)) {
        throw "Unexpected bytes at hook site 2. Found: $(Format-BytesAt $Data $Hook2Offset $Hook2Old.Length)"
    }

    if (!(Test-BytesAt $Data $CaveOffset $CaveOld)) {
        throw "The code cave is not empty. This Kain.exe may already be modified."
    }

    if (!(Test-Path -LiteralPath $BackupPath)) {
        Copy-Item -LiteralPath $ExePath -Destination $BackupPath
    }

    foreach ($offset in $SpeedOffsets) {
        Set-BytesAt $Data $offset $SpeedNew
    }

    Set-BytesAt $Data $Hook1Offset $Hook1New
    Set-BytesAt $Data $Hook2Offset $Hook2New
    Set-BytesAt $Data $CaveOffset $CaveNew

    [IO.File]::WriteAllBytes($ExePath, $Data)
    Write-Host "Installed Faster Kain."
    Write-Host "Backup created at: $BackupPath"
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

    if (!(Test-Installed)) {
        throw "Cannot safely uninstall: no backup was found and Kain.exe does not match Faster Kain's installed byte patterns."
    }

    foreach ($offset in $SpeedOffsets) {
        Set-BytesAt $Data $offset $SpeedOld
    }

    Set-BytesAt $Data $Hook1Offset $Hook1Old
    Set-BytesAt $Data $Hook2Offset $Hook2Old
    Set-BytesAt $Data $CaveOffset $CaveOld

    [IO.File]::WriteAllBytes($ExePath, $Data)
    Write-Host "Uninstalled Faster Kain by reversing the patch bytes."
    exit 0
}
