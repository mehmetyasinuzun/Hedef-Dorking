[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir,

    [Parameter(Mandatory = $true)]
    [string]$MainExe,

    [string]$OutDir = "dist",
    [string]$PackageName = "portable_app",
    [string[]]$Exclude = @("*.log"),
    [switch]$ZipOnly
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Test-IsExcluded {
    param(
        [string]$RelativePath,
        [string]$FileName,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }
        if ($RelativePath -like $pattern -or $FileName -like $pattern) {
            return $true
        }
    }

    return $false
}

if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    throw "SourceDir bulunamadi: $SourceDir"
}

$sourcePath = (Resolve-Path -LiteralPath $SourceDir).Path
$mainExeRelative = $MainExe -replace "/", "\\"
$mainExeAbsolute = Join-Path $sourcePath $mainExeRelative

if (-not (Test-Path -LiteralPath $mainExeAbsolute -PathType Leaf)) {
    throw "MainExe bulunamadi: $mainExeAbsolute"
}

if ([System.IO.Path]::IsPathRooted($OutDir)) {
    $outPath = $OutDir
} else {
    $outPath = Join-Path (Get-Location).Path $OutDir
}
$outPath = [System.IO.Path]::GetFullPath($outPath)

if (-not (Test-Path -LiteralPath $outPath -PathType Container)) {
    New-Item -ItemType Directory -Path $outPath | Out-Null
}

$stageRoot = Join-Path $env:TEMP ("portable_pack_" + [guid]::NewGuid().ToString("N"))
$payloadDir = Join-Path $stageRoot "payload"
$sfxDir = Join-Path $stageRoot "sfx"

New-Item -ItemType Directory -Path $payloadDir -Force | Out-Null
New-Item -ItemType Directory -Path $sfxDir -Force | Out-Null

try {
    Write-Info "Dosyalar paketleme klasorune kopyalaniyor..."
    $allFiles = Get-ChildItem -LiteralPath $sourcePath -Recurse -File
    foreach ($file in $allFiles) {
        $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart('\\')

        if (Test-IsExcluded -RelativePath $relativePath -FileName $file.Name -Patterns $Exclude) {
            continue
        }

        $destinationPath = Join-Path $payloadDir $relativePath
        $destinationDir = Split-Path -Path $destinationPath -Parent
        if (-not (Test-Path -LiteralPath $destinationDir -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force
    }

    $stagedMainExe = Join-Path $payloadDir $mainExeRelative
    if (-not (Test-Path -LiteralPath $stagedMainExe -PathType Leaf)) {
        throw "MainExe paketleme asamasinda bulunamadi. Exclude listesi MainExe'yi elemis olabilir."
    }

    $zipPath = Join-Path $outPath ($PackageName + ".zip")
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Write-Info "ZIP olusturuluyor: $zipPath"
    Compress-Archive -Path (Join-Path $payloadDir '*') -DestinationPath $zipPath -CompressionLevel Optimal

    if ($ZipOnly) {
        Write-Info "Sadece ZIP modunda tamamlandi."
        Write-Output "ZIP=$zipPath"
        return
    }

    $iexpress = Get-Command -Name iexpress.exe -ErrorAction SilentlyContinue
    if ($null -eq $iexpress) {
        throw "iexpress.exe bulunamadi. Sadece ZIP almak icin -ZipOnly parametresi kullanilabilir."
    }

    $payloadZip = Join-Path $sfxDir "payload.zip"
    Copy-Item -LiteralPath $zipPath -Destination $payloadZip -Force

    $runCmdPath = Join-Path $sfxDir "run.cmd"
    $runCmdContent = @"
@echo off
setlocal
set "TARGET=%TEMP%\\$PackageName"
if exist "%TARGET%" rmdir /s /q "%TARGET%"
mkdir "%TARGET%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%~dp0payload.zip' -DestinationPath '%TARGET%' -Force"
if errorlevel 1 exit /b 1
start "" "%TARGET%\\$mainExeRelative"
exit /b 0
"@
    Set-Content -LiteralPath $runCmdPath -Value $runCmdContent -Encoding ASCII

    $portableExePath = Join-Path $outPath ($PackageName + "_portable.exe")
    if (Test-Path -LiteralPath $portableExePath) {
        Remove-Item -LiteralPath $portableExePath -Force
    }

    $sourceFilesPath = $sfxDir
    if (-not $sourceFilesPath.EndsWith("\\")) {
        $sourceFilesPath += "\\"
    }

    $sedPath = Join-Path $sfxDir "package.sed"
    $sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$portableExePath
FriendlyName=$PackageName Portable
AppLaunched=run.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles

[SourceFiles]
SourceFiles0=$sourceFilesPath

[SourceFiles0]
%FILE0%=
%FILE1%=

[Strings]
FILE0=run.cmd
FILE1=payload.zip
"@
    Set-Content -LiteralPath $sedPath -Value $sedContent -Encoding ASCII

    Write-Info "Self-extracting EXE olusturuluyor: $portableExePath"
    & $iexpress.Source /N /Q /M $sedPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "IExpress paketleme hatasi. Cikis kodu: $LASTEXITCODE"
    }

    if (-not (Test-Path -LiteralPath $portableExePath -PathType Leaf)) {
        throw "Portable EXE olusturulamadi: $portableExePath"
    }

    Write-Output "ZIP=$zipPath"
    Write-Output "SFX=$portableExePath"
    Write-Info "Paketleme tamamlandi."
}
finally {
    if (Test-Path -LiteralPath $stageRoot -PathType Container) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
