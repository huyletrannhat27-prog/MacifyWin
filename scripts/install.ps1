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

# 2. Tao System Restore Point & Backup Registry
New-MacifyRestorePoint
Write-Step "Sao luu cau hinh Registry goc"
Backup-RegistryKey "HKCU\Control Panel\Cursors" "cursors.reg"
Backup-RegistryKey "HKCU\Control Panel\Desktop" "desktop.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "personalize.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "explorer_advanced.reg"
Backup-RegistryKey "HKCU\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" "font_substitutes.reg"

# 3. Cai dat cac cong cu qua winget
Write-Step "Cai dat cac cong cu giao dien qua winget"
$packages = @(
    @{ Id = "Seelen.SeelenUI";        Name = "Seelen UI (Dock & Menu Bar)" },
    @{ Id = "RamenSoftware.Windhawk"; Name = "Windhawk (Mods & Animation)" },
    @{ Id = "FilesCommunity.Files";   Name = "Files App (Finder)" },
    @{ Id = "AutoHotkey.AutoHotkey";  Name = "AutoHotkey v2 (Phim tat)" },
    @{ Id = "MacType.MacType";        Name = "MacType (Lam min chu)" }
)
if ($win.IsWin11) {
    $packages += @{ Id = "MicaForEveryone.MicaForEveryone"; Name = "Mica For Everyone (Blur/Bo goc)" }
}
foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Name $pkg.Name
}

# 4. Import cau hinh tu thu muc configs/
Write-Step "Ap dung cau hinh cho cac ung dung"

$seelenCfgDir = Join-Path $env:APPDATA "com.seelen.seelen-ui"
if (Test-Path "$script:RepoRoot\configs\seelen-ui\settings.json") {
    New-Item -ItemType Directory -Force -Path $seelenCfgDir | Out-Null
    Copy-Item "$script:RepoRoot\configs\seelen-ui\settings.json" "$seelenCfgDir\settings.json" -Force
    Write-Ok "Da nap cau hinh Seelen UI."
}

if ($win.IsWin11 -and (Test-Path "$script:RepoRoot\configs\mica-for-everyone\MicaForEveryone.conf")) {
    $mfeDir = Join-Path $env:LOCALAPPDATA "Mica For Everyone"
    New-Item -ItemType Directory -Force -Path $mfeDir | Out-Null
    Copy-Item "$script:RepoRoot\configs\mica-for-everyone\MicaForEveryone.conf" "$mfeDir\MicaForEveryone.conf" -Force
    Write-Ok "Da nap cau hinh Mica For Everyone."
}

$whReg = "$script:RepoRoot\configs\windhawk\windhawk-mods.reg"
if ((Test-Path $whReg) -and (Get-Service "WindhawkService" -ErrorAction SilentlyContinue)) {
    Stop-Service "WindhawkService" -Force -ErrorAction SilentlyContinue
    & reg.exe import $whReg 2>$null | Out-Null
    Start-Service "WindhawkService" -ErrorAction SilentlyContinue
    Write-Ok "Da nap cau hinh Windhawk mods."
}

$filesCfgDir = Join-Path $env:LOCALAPPDATA "Files\Settings"
if (Test-Path "$script:RepoRoot\configs\files-app\user_settings.json") {
    New-Item -ItemType Directory -Force -Path $filesCfgDir | Out-Null
    Copy-Item "$script:RepoRoot\configs\files-app\user_settings.json" "$filesCfgDir\user_settings.json" -Force
    Write-Ok "Da nap cau hinh Files App."
}

$mactypeIniDir = "$env:ProgramFiles\MacType\ini"
if ((Test-Path $mactypeIniDir) -and (Test-Path "$script:RepoRoot\configs\mactype\MacifyWin.ini")) {
    Copy-Item "$script:RepoRoot\configs\mactype\MacifyWin.ini" "$mactypeIniDir\MacifyWin.ini" -Force
    Write-Ok "Da chep profile MacifyWin.ini cho MacType."
}

$ahkScript = "$script:RepoRoot\configs\autohotkey\macos-shortcuts.ahk"
$ahkExe = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
if (Test-Path $ahkScript) {
    $startupDir = [Environment]::GetFolderPath("Startup")
    $wsh = New-Object -ComObject WScript.Shell
    $sc = $wsh.CreateShortcut((Join-Path $startupDir "MacifyWin-Shortcuts.lnk"))
    $sc.TargetPath = $ahkExe
    $sc.Arguments  = "`"$ahkScript`""
    $sc.Save()
    Write-Ok "Da tao shortcut khoi dong cung Windows cho AutoHotkey."
}

# 5. Chay cac script tinh chinh he thong, tai nguyen va app theme
& "$PSScriptRoot\apply-tweaks.ps1" -Theme $Theme
& "$PSScriptRoot\apply-assets.ps1"
& "$PSScriptRoot\setup-apps-theme.ps1" -Theme $Theme

# 6. Khoi dong lai Explorer va bat cac cong cu giao dien ngay lap tuc
Restart-ExplorerSafe

Write-Step "Khoi chay giao dien MacifyWin"
$seelenExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Seelen UI", "$env:ProgramFiles\Seelen UI" -Filter "*Seelen*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($seelenExe) { Start-Process $seelenExe.FullName }

$mfeExe = "$env:ProgramFiles\Mica For Everyone\MicaForEveryone.exe"
if ($win.IsWin11 -and (Test-Path $mfeExe)) { Start-Process $mfeExe }

if ((Test-Path $ahkExe) -and (Test-Path $ahkScript)) {
    Start-Process $ahkExe -ArgumentList "`"$ahkScript`""
}

Write-Step "Hoan tat! Windows da duoc chuyen sang giao dien MacifyWin."
Write-Host "  Neu muon quay lai Windows goc bat cu luc nao, chi can chay uninstall.bat" -ForegroundColor Cyan
