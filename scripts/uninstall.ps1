param([switch]$UninstallApps)
. "$PSScriptRoot\common.ps1"

Write-Host "=========================================" -ForegroundColor Yellow
Write-Host "  MacifyWin - Khoi phuc Windows mac dinh " -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

# 1. Tat cac tien ich giao dien dang chay
Write-Step "Dung cac ung dung giao dien"
@("Seelen UI", "seelen-ui", "MicaForEveryone", "AutoHotkey64", "AutoHotkey", "MacTrafficLights", "QuickLook") | ForEach-Object {
    Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
}
if (Get-Service "WindhawkService" -ErrorAction SilentlyContinue) {
    Stop-Service "WindhawkService" -Force -ErrorAction SilentlyContinue
}

# Xoa Startup shortcuts
$startupDir = [Environment]::GetFolderPath("Startup")
@("MacifyWin-Shortcuts.lnk", "MacifyWin-TrafficLights.lnk", "MacifyWin-MicaForEveryone.lnk") | ForEach-Object {
    $p = Join-Path $startupDir $_
    if (Test-Path $p) { Remove-Item $p -Force }
}

# 2. Khoi phuc Registry tu thu muc backup (bao gom Taskbar StuckRects3)
Write-Step "Khoi phuc Registry goc"
if (Test-Path $script:BackupDir) {
    Get-ChildItem $script:BackupDir -Filter *.reg | ForEach-Object {
        & reg.exe import $_.FullName 2>$null | Out-Null
        Write-Ok "Da khoi phuc $($_.Name)"
    }
    $vscodeBak = Join-Path $script:BackupDir "vscode_settings.json"
    $vscodeDst = Join-Path $env:APPDATA "Code\User\settings.json"
    if (Test-Path $vscodeBak) {
        Copy-Item $vscodeBak $vscodeDst -Force
        Write-Ok "Da khoi phuc VS Code settings.json."
    }
    $wtBak = Join-Path $script:BackupDir "wt_settings.json"
    if (Test-Path $wtBak) {
        @(
            (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
            (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
        ) | Where-Object { Test-Path $_ } | ForEach-Object {
            Copy-Item $wtBak $_ -Force
            Write-Ok "Da khoi phuc Windows Terminal settings.json."
        }
    }
} else {
    Write-Warn "Khong tim thay thu muc backup. Dang reset con tro ve mac dinh..."
    Remove-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name * -ErrorAction SilentlyContinue
}

# 3. Tuy chon go ung dung da cai qua winget
$ans = if ($UninstallApps) { "y" } else { Read-Host "`nBan co muon go bo cac app da cai (Seelen UI, Windhawk, MicaForEveryone, MacType)? [y/N]" }
if ($ans -match "^[Yy]") {
    Write-Step "Go cai dat ung dung qua winget"
    @("Seelen.SeelenUI", "RamenSoftware.Windhawk", "MicaForEveryone.MicaForEveryone", "MacType.MacType", "QL-Win.QuickLook") | ForEach-Object {
        & winget uninstall --id $_ -e --silent 2>&1 | Out-Null
        Write-Ok "Da go $_ (neu co)"
    }
}

Restart-ExplorerSafe
Write-Step "Hoan tat khoi phuc! Vui long Sign out / Restart de hoan tat."
