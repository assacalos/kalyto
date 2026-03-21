# Script: pub_get_et_patches.ps1
# 1. Execute "flutter pub get"
# 2. Applique le correctif namespace + compileSdkVersion 35 sur flutter_app_badger (AGP + lStar)
# Utilisez ce script a la place de "flutter pub get" pour que le correctif soit toujours applique.

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Execution de: flutter pub get" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Appliquer le correctif flutter_app_badger (namespace manquant pour AGP)
$PubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache" }
$HostedPath = Join-Path $PubCache "hosted\pub.dev"
if (-not (Test-Path $HostedPath)) {
    Write-Host "Cache Pub non trouve: $HostedPath" -ForegroundColor Yellow
    exit 0
}

$BadgerDir = Get-ChildItem -Path $HostedPath -Directory -Filter "flutter_app_badger-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $BadgerDir) {
    Write-Host "Package flutter_app_badger non trouve dans le cache." -ForegroundColor Yellow
    exit 0
}

$BuildGradle = Join-Path $BadgerDir.FullName "android\build.gradle"
if (-not (Test-Path $BuildGradle)) {
    Write-Host "Fichier build.gradle non trouve: $BuildGradle" -ForegroundColor Yellow
    exit 0
}

$Content = Get-Content $BuildGradle -Raw
$NamespaceLine = "namespace 'fr.g123k.flutterappbadge.flutterappbadger'"
$Modified = $false

# Inserer la ligne namespace apres "android {" si pas deja presente
if ($Content -notmatch [regex]::Escape($NamespaceLine)) {
    $Content = $Content -replace "(android \{\r?\n)(\s+compileSdkVersion)", "`$1    $NamespaceLine`r`n`$2"
    $Modified = $true
}

# Forcer compileSdkVersion 35 pour eviter "resource android:attr/lStar not found"
if ($Content -notmatch "compileSdkVersion\s+35\b") {
    $Content = $Content -replace "compileSdkVersion\s+\d+", "compileSdkVersion 35"
    $Modified = $true
}

if ($Modified) {
    Set-Content -Path $BuildGradle -Value $Content.TrimEnd() -NoNewline
    Write-Host "Correctif flutter_app_badger (namespace + compileSdk 35) applique avec succes." -ForegroundColor Green
} else {
    Write-Host "Correctif flutter_app_badger deja applique." -ForegroundColor Green
}
