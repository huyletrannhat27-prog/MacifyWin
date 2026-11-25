param([switch]$UninstallApps)
. "$PSScriptRoot\common.ps1"

Write-Host "=========================================" -ForegroundColor Yellow
Write-Host "  MacifyWin - Khoi phuc Windows mac dinh " -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

# 1. Tat cac tien ich giao dien dang chay
Write-Step "Dung cac ung dung giao dien"
@("Seelen UI", "MicaForEveryone", "AutoHotkey64", "AutoHotkey") | ForEach-Object {
    Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
}
if (Get-Service "WindhawkService" -ErrorAction SilentlyContinue) {
    Stop-Service "WindhawkService" -Force -ErrorAction SilentlyContinue
}

$ahkLnk = Join-Path ([Environment]::GetFolderPath("Startup")) "MacifyWin-Shortcuts.lnk"
if (Test-Path $ahkLnk) { Remove-Item $ahkLnk -Force }

# 2. Khoi phuc Registry tu thu muc backup
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
} else {
    Write-Warn "Khong tim thay thu muc backup. Dang reset con tro ve mac dinh..."
    Remove-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name * -ErrorAction SilentlyContinue
}

# 3. Tuy chon go ung dung da cai qua winget
$ans = if ($UninstallApps) { "y" } else { Read-Host "`nBan co muon go bo cac app da cai (Seelen UI, Windhawk, MicaForEveryone, MacType)? [y/N]" }
if ($ans -match "^[Yy]") {
    Write-Step "Go cai dat ung dung qua winget"
    @("Seelen.SeelenUI", "RamenSoftware.Windhawk", "MicaForEveryone.MicaForEveryone", "MacType.MacType") | ForEach-Object {
        & winget uninstall --id $_ -e --silent 2>&1 | Out-Null
        Write-Ok "Da go $_ (neu co)"
    }
}

Restart-ExplorerSafe
Write-Step "Hoan tat khoi phuc! Vui long Sign out / Restart de hoan tat."

