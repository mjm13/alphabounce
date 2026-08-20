<#
.SYNOPSIS
    One-click reproducible build: export debug APK -> zipalign -> apksigner sign -> verify.
    Output: android/build/alphabounce-debug.apk (signed, installable via adb).

.DESCRIPTION
    Toolchain (Godot / JDK / Android SDK) and keystore are recorded as ABSOLUTE paths in
    android/export_presets.cfg, which breaks whenever the repo moves to another drive or
    directory. This script rewrites those paths from the current repo root before every
    build so the build stays reproducible after a move.

    ASCII-only on purpose: Windows PowerShell 5.1 reads .ps1 as ANSI unless the file has a
    UTF-8 BOM, and this repo mandates UTF-8 without BOM (see xijia-safe-file-write).
    Non-ASCII text here would be mangled and break parsing.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/build_android.ps1
#>
[CmdletBinding()]
param(
    [string]$OutName = "alphabounce-debug.apk",
    [string]$KeyAlias = "alphabounce"
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$RepoRootFwd = $RepoRoot -replace '\\', '/'

$GodotVersion = "4.7.1.stable"
$Godot      = Join-Path $RepoRoot "tools\godot\Godot_v4.7.1-stable_win64_console.exe"
$Jdk        = Join-Path $RepoRoot "tools\jdk\jdk17"
$BuildTools = Join-Path $RepoRoot "tools\android-sdk\build-tools\34.0.0"
$ZipAlign   = Join-Path $BuildTools "zipalign.exe"
$ApkSigner  = Join-Path $BuildTools "apksigner.bat"
$Keystore   = Join-Path $RepoRoot "android\debug.keystore"
$KeyEnv     = Join-Path $RepoRoot "android\keystore.local.env"
$Presets    = Join-Path $RepoRoot "android\export_presets.cfg"
$ProjectDir = Join-Path $RepoRoot "android"
$BuildDir   = Join-Path $ProjectDir "build"

foreach ($dep in @($Godot, $ZipAlign, $ApkSigner, $Keystore, $KeyEnv, $Presets)) {
    if (-not (Test-Path $dep)) {
        throw "Missing build dependency: $dep (tools/ and keystore are not committed; prepare them locally first)"
    }
}

Write-Host "[1/5] Sync export_presets.cfg toolchain paths -> $RepoRootFwd"
$expected = [ordered]@{
    "android/android_sdk_path" = "$RepoRootFwd/tools/android-sdk"
    "android/java_sdk_path"    = "$RepoRootFwd/tools/jdk/jdk17"
    "custom_template/debug"    = "$RepoRootFwd/tools/godot/templates/$GodotVersion/android_debug.apk"
    "custom_template/release"  = "$RepoRootFwd/tools/godot/templates/$GodotVersion/android_release.apk"
    "android/debug_keystore"   = "$RepoRootFwd/android/debug.keystore"
}
$lines = [System.IO.File]::ReadAllLines($Presets)
$changed = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    foreach ($key in $expected.Keys) {
        if ($lines[$i].StartsWith("$key=")) {
            $want = "$key=`"$($expected[$key])`""
            if ($lines[$i] -ne $want) { $lines[$i] = $want; $changed = $true }
        }
    }
}
if ($changed) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Presets, (($lines -join "`n") + "`n"), $utf8NoBom)
    Write-Host "      updated (recorded paths did not match current repo root)"
} else {
    Write-Host "      already current, no change"
}

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
$unsignedName = "alphabounce-unsigned.apk"
$unsigned = Join-Path $BuildDir $unsignedName
$aligned  = Join-Path $BuildDir "alphabounce-aligned.apk"
$outApk   = Join-Path $BuildDir $OutName
$exportLog = Join-Path $BuildDir "export.log"
Remove-Item -Force -ErrorAction SilentlyContinue $unsigned, $aligned, $outApk

Write-Host "[2/5] Godot headless export (prebuilt template, gradle_build=false)"
& $Godot --headless --path $ProjectDir --export-debug "Android" "build/$unsignedName" *> $exportLog
if (-not (Test-Path $unsigned)) {
    Write-Host (Get-Content $exportLog -Raw)
    throw "Export failed: $unsigned not produced (see android/build/export.log)"
}

Write-Host "[3/5] zipalign (4-byte)"
& $ZipAlign -f -p 4 $unsigned $aligned
if ($LASTEXITCODE -ne 0) { throw "zipalign failed (exit $LASTEXITCODE)" }

Write-Host "[4/5] apksigner sign (v1+v2)"
$passLine = Select-String -Path $KeyEnv -Pattern '^\s*KEYSTORE_PASS\s*=\s*(.+?)\s*$'
if (-not $passLine) { throw "KEYSTORE_PASS not found in $KeyEnv" }
$pass = $passLine.Matches[0].Groups[1].Value
$env:JAVA_HOME = $Jdk
& $ApkSigner sign --ks $Keystore --ks-key-alias $KeyAlias `
    --ks-pass "pass:$pass" --key-pass "pass:$pass" --out $outApk $aligned
if ($LASTEXITCODE -ne 0) { throw "apksigner sign failed (exit $LASTEXITCODE)" }

Write-Host "[5/5] apksigner verify"
& $ApkSigner verify $outApk
if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed (exit $LASTEXITCODE)" }

Remove-Item -Force -ErrorAction SilentlyContinue $unsigned, $aligned, "$outApk.idsig"

$size = [math]::Round((Get-Item $outApk).Length / 1MB, 1)
Write-Host ""
Write-Host "BUILD OK: $outApk ($size MB, signed and verified)"
Write-Host "Install:  tools\android-sdk\platform-tools\adb.exe install -r $outApk"
