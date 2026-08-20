<#
.SYNOPSIS
    Mirror upstream sprites and fonts into android/assets/.

.DESCRIPTION
    Replaces the lost tools/sync_assets.py. The previous script lived under tools/,
    which is gitignored, so it vanished together with the toolchain; this one is
    committed under scripts/.

    Source is an EternalTwin AlphaBounce clone. If it is absent the script clones it
    (shallow) so a fresh checkout can populate assets without manual setup.

    Godot's res:// paths dislike spaces, so " " in filenames becomes "_".
    Fonts are copied as .woff (Godot 4 loads WOFF natively; no conversion needed).

    Only the sprite directories consumed by delivered phases are mirrored by default
    (~170 KB). Mirroring all 4113 sprites costs 24.6 MB and inflates the APK by the
    same amount: export_presets.cfg cannot filter them out, because Godot's only
    "pack just what is used" mode requires an explicit scene/resource selection.
    Extend -Dirs as each phase lands; docs/ASSETS.md section 7 maps phase -> directory.

    ASCII-only on purpose: Windows PowerShell 5.1 reads .ps1 as ANSI unless the file
    has a UTF-8 BOM, and this repo mandates UTF-8 without BOM.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/sync_assets.ps1
    powershell -ExecutionPolicy Bypass -File scripts/sync_assets.ps1 -All
#>
[CmdletBinding()]
param(
    [string]$SourceRepo,
    [string[]]$Dirs = @(
        # P1 core gameplay
        "mcPad", "mcBall", "ballMain",
        # P2 brick system
        "mcBlock", "mcBlockSmc", "blockMissile",
        # P2 destruction particles
        "part*"
    ),
    [switch]$All,
    [string]$CloneUrl = "https://gitlab.com/eternaltwin/alphabounce/alphabounce.git"
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not $SourceRepo) {
    $SourceRepo = Join-Path (Split-Path $RepoRoot -Parent) "EternalTwin-Alphabounce"
}

if (-not (Test-Path $SourceRepo)) {
    Write-Host "Upstream not found at $SourceRepo -- cloning (shallow)"
    & git clone --depth 1 $CloneUrl $SourceRepo
    if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
}

$srcImages = Join-Path $SourceRepo "frontend\src\static\images"
$srcFonts  = Join-Path $SourceRepo "frontend\src\static\fonts"
foreach ($p in @($srcImages, $srcFonts)) {
    if (-not (Test-Path $p)) { throw "Upstream layout unexpected, missing: $p" }
}

$dstSprites = Join-Path $RepoRoot "android\assets\sprites"
$dstFonts   = Join-Path $RepoRoot "android\assets\fonts"
New-Item -ItemType Directory -Force -Path $dstSprites, $dstFonts | Out-Null

$srcImagesFull = (Resolve-Path $srcImages).Path
if ($All) {
    Write-Host "Mirroring ALL sprites: $srcImages -> $dstSprites"
    $sources = Get-ChildItem $srcImages -Recurse -File -Filter *.png
} else {
    Write-Host "Mirroring sprites for delivered phases ($($Dirs -join ', '))"
    $sources = @()
    foreach ($pattern in $Dirs) {
        $matched = Get-ChildItem $srcImages -Directory -Filter $pattern
        if (-not $matched) { Write-Warning "no upstream sprite directory matches '$pattern'" }
        foreach ($dir in $matched) {
            $sources += Get-ChildItem $dir.FullName -Recurse -File -Filter *.png
        }
    }
}

$copied = 0
foreach ($png in $sources) {
    $rel = $png.FullName.Substring($srcImagesFull.Length).TrimStart('\')
    $target = Join-Path $dstSprites ($rel -replace ' ', '_')
    $targetDir = Split-Path $target -Parent
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
    Copy-Item $png.FullName $target -Force
    $copied++
}
Write-Host "  $copied png"

Write-Host "Mirroring fonts: $srcFonts -> $dstFonts"
$fonts = 0
Get-ChildItem $srcFonts -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $dstFonts ($_.Name -replace ' ', '_')) -Force
    $fonts++
}
Write-Host "  $fonts font(s)"

$kb = [math]::Round((Get-ChildItem (Join-Path $RepoRoot "android\assets") -Recurse -File | Measure-Object Length -Sum).Sum / 1KB, 1)
Write-Host ""
Write-Host "SYNC OK: android/assets ($kb KB)"
if ($All) {
    Write-Host "NOTE: -All was used; every synced sprite is packed into the APK."
}
