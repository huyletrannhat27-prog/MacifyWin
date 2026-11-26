param(
    [ValidateSet("Dark", "Light")]
    [string]$Theme = "Dark"
)

$ErrorActionPreference = "Continue"
. "$PSScriptRoot\common.ps1"

$win = Get-WindowsInfo
Write-Host "=========================================" -ForegroundColor Magenta
Write-Host "   MacifyWin - macOS Look for Windows    " -ForegroundColor Magenta
Write-Host "   Windows Build: $($win.Build) (Win11: $($win.IsWin11))" -ForegroundColor DarkGray
Write-Host "=========================================" -ForegroundColor Magenta

# 1. Kiem tra winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "Khong tim thay 'winget'. Vui long cai 'App Installer' tu Microsoft Store roi thu lai."
    exit 1
}

# 2. Tao System Restore Point & Backup Registry (bao gom StuckRects3 de khoi phuc Taskbar)
New-MacifyRestorePoint
Write-Step "Sao luu cau hinh Registry goc"
Backup-RegistryKey "HKCU\Control Panel\Cursors" "cursors.reg"
Backup-RegistryKey "HKCU\Control Panel\Desktop" "desktop.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "personalize.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "explorer_advanced.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" "stuckrects3.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" "font_substitutes.reg"

# 3. Cai dat cac cong cu qua winget
Write-Step "Cai dat cac cong cu giao dien qua winget"
$packages = @(
    @{ Id = "Seelen.SeelenUI";        Name = "Seelen UI (Dock & Top Menu Bar)" },
    @{ Id = "RamenSoftware.Windhawk"; Name = "Windhawk (Mods & Animation)" },
    @{ Id = "FilesCommunity.Files";   Name = "Files App (Finder)" },
    @{ Id = "QL-Win.QuickLook";       Name = "QuickLook (Space xem nhanh file)" },
    @{ Id = "AutoHotkey.AutoHotkey";  Name = "AutoHotkey v2 (Phim tat macOS)" },
    @{ Id = "MacType.MacType";        Name = "MacType (Lam min chu)" }
)
if ($win.IsWin11) {
    $packages += @{ Id = "MicaForEveryone.MicaForEveryone"; Name = "Mica For Everyone (Blur/Bo goc)" }
}
foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Name $pkg.Name
}

# 4. Bien dich & cai dat MacTrafficLights (nut Do-Vang-Xanh ben trai cua so)
Write-Step "Bien dich MacTrafficLights (nut Do - Vang - Xanh kieu macOS)"
$trafficSrc = "$script:RepoRoot\tools\MacTrafficLights.cs"
$trafficExe = Join-Path $script:DataDir "MacTrafficLights.exe"
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if ((Test-Path $trafficSrc) -and (Test-Path $csc)) {
    New-Item -ItemType Directory -Force -Path $script:DataDir | Out-Null
    Stop-Process -Name "MacTrafficLights" -Force -ErrorAction SilentlyContinue
    & $csc /nologo /target:winexe /out:"$trafficExe" /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "$trafficSrc" 2>&1 | Out-Null
    if (Test-Path $trafficExe) {
        Write-Ok "Da bien dich thanh cong MacTrafficLights.exe"
    } else {
        Write-Warn "Bien dich MacTrafficLights that bai."
    }
}

# 5. Import cau hinh tu thu muc configs/
Write-Step "Ap dung cau hinh cho cac ung dung"

# Seelen UI (ho tro ca 2 duong dan MSIX/AppData)
$seelenCfgSrc = "$script:RepoRoot\configs\seelen-ui\settings.json"
if (Test-Path $seelenCfgSrc) {
    $seelenDirs = @(
        (Join-Path $env:APPDATA "com.seelen.seelen-ui"),
        (Join-Path $env:LOCALAPPDATA "com.seelen.seelen-ui")
    )
    foreach ($d in $seelenDirs) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        $dst = Join-Path $d "settings.json"
        if (-not (Test-Path $dst)) {
            Copy-Item $seelenCfgSrc $dst -Force
        }
    }
    Write-Ok "Da nap cau hinh Seelen UI (Dock + Top Menu Bar)."
}

# Mica For Everyone (Win 11)
if ($win.IsWin11 -and (Test-Path "$script:RepoRoot\configs\mica-for-everyone\MicaForEveryone.conf")) {
    $mfeDir = Join-Path $env:LOCALAPPDATA "Mica For Everyone"
    New-Item -ItemType Directory -Force -Path $mfeDir | Out-Null
    Copy-Item "$script:RepoRoot\configs\mica-for-everyone\MicaForEveryone.conf" "$mfeDir\MicaForEveryone.conf" -Force
    Write-Ok "Da nap cau hinh Mica For Everyone."
}

# Windhawk: Neu co windhawk-cli.exe thi cai truc tiep mods; sau do import settings
$whCli = "$env:ProgramFiles\Windhawk\windhawk-cli.exe"
if (Test-Path $whCli) {
    Write-Host "  -> Dang cai va bien dich Windhawk mods (co the mat 15-30s)..." -ForegroundColor DarkCyan
    $modsToInstall = @("macos-minimize-animation", "titlebar-for-everyone")
    if ($win.IsWin11) {
        $modsToInstall += @("windows-11-start-menu-styler", "taskbar-dock-animation")
    }
    foreach ($m in $modsToInstall) {
        & $whCli mod install $m 2>&1 | Out-Null
        Write-Ok "Da cai Windhawk mod: $m"
    }
}
$whReg = "$script:RepoRoot\configs\windhawk\windhawk-mods.reg"
if ((Test-Path $whReg) -and (Get-Service "WindhawkService" -ErrorAction SilentlyContinue)) {
    Stop-Service "WindhawkService" -Force -ErrorAction SilentlyContinue
    & reg.exe import $whReg 2>$null | Out-Null
    Start-Service "WindhawkService" -ErrorAction SilentlyContinue
    Write-Ok "Da nap cau hinh Windhawk mods."
}

# MacType profile
$mactypeIniDir = "$env:ProgramFiles\MacType\ini"
if ((Test-Path $mactypeIniDir) -and (Test-Path "$script:RepoRoot\configs\mactype\MacifyWin.ini")) {
    Copy-Item "$script:RepoRoot\configs\mactype\MacifyWin.ini" "$mactypeIniDir\MacifyWin.ini" -Force
    Write-Ok "Da chep profile MacifyWin.ini cho MacType."
}

# Startup shortcuts (AutoHotkey, MacTrafficLights, Seelen UI)
$startupDir = [Environment]::GetFolderPath("Startup")
$wsh = New-Object -ComObject WScript.Shell

$ahkScript = "$script:RepoRoot\configs\autohotkey\macos-shortcuts.ahk"
$ahkExe = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
if ((Test-Path $ahkScript) -and (Test-Path $ahkExe)) {
    $sc = $wsh.CreateShortcut((Join-Path $startupDir "MacifyWin-Shortcuts.lnk"))
    $sc.TargetPath = $ahkExe
    $sc.Arguments  = "`"$ahkScript`""
    $sc.Save()
    Write-Ok "Da tao shortcut khoi dong cho AutoHotkey."
}

if (Test-Path $trafficExe) {
    $sc2 = $wsh.CreateShortcut((Join-Path $startupDir "MacifyWin-TrafficLights.lnk"))
    $sc2.TargetPath = $trafficExe
    $sc2.Save()
    Write-Ok "Da tao shortcut khoi dong cho MacTrafficLights."
}

$mfeExe = "$env:ProgramFiles\Mica For Everyone\MicaForEveryone.exe"
if ($win.IsWin11 -and (Test-Path $mfeExe)) {
    $sc3 = $wsh.CreateShortcut((Join-Path $startupDir "MacifyWin-MicaForEveryone.lnk"))
    $sc3.TargetPath = $mfeExe
    $sc3.Save()
    Write-Ok "Da tao shortcut khoi dong cho Mica For Everyone."
}

# 6. Chay cac script tinh chinh he thong, tai nguyen va app theme
& "$PSScriptRoot\apply-tweaks.ps1" -Theme $Theme
& "$PSScriptRoot\apply-assets.ps1"
& "$PSScriptRoot\setup-apps-theme.ps1" -Theme $Theme

# 7. Khoi dong lai Explorer de an Taskbar goc va ap dung theme
Restart-ExplorerSafe

# 8. Khoi chay tat ca giao dien MacifyWin ngay lap tuc (ho tro ca MSIX & EXE cho Seelen UI)
Write-Step "Khoi chay giao dien MacifyWin"

$seelenStarted = $false
$seelenStartApp = Get-StartApps | Where-Object { $_.Name -like "*Seelen*" } | Select-Object -First 1
if ($seelenStartApp) {
    Start-Process "explorer.exe" "shell:AppsFolder\$($seelenStartApp.AppID)"
    $seelenStarted = $true
    Write-Ok "Da khoi chay Seelen UI (Dock & Top Menu Bar)."
} else {
    $seelenPkg = Get-AppxPackage "*Seelen*" | Select-Object -First 1
    if ($seelenPkg) {
        Start-Process "explorer.exe" "shell:AppsFolder\$($seelenPkg.PackageFamilyName)!App"
        $seelenStarted = $true
        Write-Ok "Da khoi chay Seelen UI (MSIX)."
    }
}
if (-not $seelenStarted) {
    Write-Warn "Khong tim thay Seelen UI de tu mo. Hay mo 'Seelen UI' thu cong tu Start Menu."
} else {
    # Doi Seelen UI tao file settings.json chuan phien ban neu can, sau do dam bao che do Dock noi kieu macOS
    $liveCfg = Join-Path $env:APPDATA "com.seelen.seelen-ui\settings.json"
    Start-Sleep -Seconds 3
    if (Test-Path $liveCfg) {
        try {
            $json = Get-Content $liveCfg -Raw | ConvertFrom-Json
            if ($json.PSObject.Properties["seelenweg"]) {
                $json.seelenweg.enabled = $true
                $json.seelenweg.position = "Bottom"
                if ($json.seelenweg.PSObject.Properties["mode"]) { $json.seelenweg.mode = "MinContent" }
                if ($json.seelenweg.PSObject.Properties["margin"]) { $json.seelenweg.margin = 10 }
                if ($json.seelenweg.PSObject.Properties["borderRadius"]) { $json.seelenweg.borderRadius = 16 }
                if ($json.seelenweg.PSObject.Properties["zoomSize"]) { $json.seelenweg.zoomSize = 66 }
            }
            if ($json.PSObject.Properties["byWidget"]) {
                $weg = $json.byWidget.PSObject.Properties["@seelen/weg"]
                if ($weg) {
                    $weg.Value.enabled = $true
                    if ($weg.Value.PSObject.Properties["position"]) { $weg.Value.position = "Bottom" }
                    if ($weg.Value.PSObject.Properties["mode"]) { $weg.Value.mode = "MinContent" }
                }
            }
            $json | ConvertTo-Json -Depth 15 | Set-Content $liveCfg -Encoding UTF8
            Write-Ok "Da dong bo che do Mac Dock noi cho Seelen UI."
        } catch {
            Write-Warn "Khong the cap nhat tu dong settings.json cua Seelen UI (ban co the nhan Win+K de chon che do Dock)."
        }
    }
}

if (Test-Path $trafficExe) {
    Start-Process $trafficExe
    Write-Ok "Da bat MacTrafficLights (nut Do - Vang - Xanh)."
}

$mfeExe = "$env:ProgramFiles\Mica For Everyone\MicaForEveryone.exe"
if ($win.IsWin11 -and (Test-Path $mfeExe)) {
    Start-Process $mfeExe
    Write-Ok "Da bat Mica For Everyone."
}

if ((Test-Path $ahkExe) -and (Test-Path $ahkScript)) {
    Start-Process $ahkExe -ArgumentList "`"$ahkScript`""
    Write-Ok "Da bat phim tat AutoHotkey."
}

$qlExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\QuickLook", "$env:ProgramFiles\QuickLook" -Filter "QuickLook.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($qlExe) {
    Start-Process $qlExe.FullName
    Write-Ok "Da bat QuickLook (nhan Space trong Finder/Explorer de xem nhanh file)."
}

Write-Step "Hoan tat! Giao dien MacifyWin da duoc kich hoat."
Write-Host "  - Neu Taskbar goc van con hien: bam phim Windows -> mo 'Seelen UI' va bat Run on Startup." -ForegroundColor Gray
Write-Host "  - Muon quay lai Windows goc: chay uninstall.bat" -ForegroundColor Cyan
